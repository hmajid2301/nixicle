package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"os"
)

// Relation describes how two versions of one append-only transcript relate.
type Relation int

const (
	Same Relation = iota
	LocalAhead
	MirrorAhead
	Diverged
)

func (r Relation) String() string {
	switch r {
	case Same:
		return "same"
	case LocalAhead:
		return "local-ahead"
	case MirrorAhead:
		return "mirror-ahead"
	default:
		return "diverged"
	}
}

// Compare decides which of two transcripts is the later version.
//
// Deliberately not mtime-based: rsync -a stamps the mirror with the REMOTE
// machine's clock, so comparing that against a locally-stamped file is only
// valid when both clocks agree. A fast remote clock would clobber newer local
// work; a slow one would silently refuse to rescue newer remote work.
//
// Transcripts are append-only, so whichever file strictly extends the other is
// the later one. That is exact, needs no clock, and detects the fork case —
// both sides appended independently — which mtime comparison cannot see.
func Compare(localPath, mirrorPath string) (Relation, error) {
	ls, err := os.Stat(localPath)
	if err != nil {
		return Diverged, err
	}
	ms, err := os.Stat(mirrorPath)
	if err != nil {
		return Diverged, err
	}

	switch {
	case ls.Size() == ms.Size():
		eq, err := prefixEqual(localPath, mirrorPath, ls.Size())
		if err != nil {
			return Diverged, err
		}
		if eq {
			return Same, nil
		}
		return Diverged, nil

	case ls.Size() > ms.Size():
		eq, err := prefixEqual(localPath, mirrorPath, ms.Size())
		if err != nil {
			return Diverged, err
		}
		if eq {
			return LocalAhead, nil
		}
		return Diverged, nil

	default:
		eq, err := prefixEqual(localPath, mirrorPath, ls.Size())
		if err != nil {
			return Diverged, err
		}
		if eq {
			return MirrorAhead, nil
		}
		return Diverged, nil
	}
}

// prefixEqual reports whether the first n bytes of both files are identical.
func prefixEqual(a, b string, n int64) (bool, error) {
	fa, err := os.Open(a)
	if err != nil {
		return false, err
	}
	defer fa.Close()
	fb, err := os.Open(b)
	if err != nil {
		return false, err
	}
	defer fb.Close()

	ba := bufio.NewReader(io.LimitReader(fa, n))
	bb := bufio.NewReader(io.LimitReader(fb, n))
	bufA := make([]byte, 64*1024)
	bufB := make([]byte, 64*1024)
	for {
		na, ea := io.ReadFull(ba, bufA)
		nb, eb := io.ReadFull(bb, bufB)
		if na != nb || !bytes.Equal(bufA[:na], bufB[:nb]) {
			return false, nil
		}
		if ea != nil || eb != nil {
			done := func(e error) bool {
				return errors.Is(e, io.EOF) || errors.Is(e, io.ErrUnexpectedEOF)
			}
			if done(ea) && done(eb) {
				return true, nil
			}
			if ea != nil && !done(ea) {
				return false, ea
			}
			return false, eb
		}
	}
}

// CompleteSize returns the length of the file up to and including its last
// newline — the portion consisting of whole records.
//
// A transcript captured while the agent was mid-write ends partway through a
// JSON object. That is the normal steady state for a live session, not a rare
// race, so promoting the file verbatim would install a corrupt final line.
// Returns 0 if the file contains no newline at all.
func CompleteSize(path string) (int64, error) {
	f, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer f.Close()
	st, err := f.Stat()
	if err != nil {
		return 0, err
	}

	const chunk = 64 * 1024
	buf := make([]byte, chunk)
	for end := st.Size(); end > 0; {
		start := end - chunk
		if start < 0 {
			start = 0
		}
		n, err := f.ReadAt(buf[:end-start], start)
		if err != nil && n == 0 {
			return 0, err
		}
		if i := bytes.LastIndexByte(buf[:n], '\n'); i >= 0 {
			return start + int64(i) + 1, nil
		}
		end = start
	}
	return 0, nil
}

// CountLines returns the number of newline-terminated records.
func CountLines(path string) int {
	f, err := os.Open(path)
	if err != nil {
		return 0
	}
	defer f.Close()
	n, buf := 0, make([]byte, 64*1024)
	for {
		c, err := f.Read(buf)
		n += bytes.Count(buf[:c], []byte{'\n'})
		if err != nil {
			return n
		}
	}
}

// CWD reads the working directory the session ran in, from the transcript
// itself. Both agents record it on most entries. Unparseable lines are skipped
// rather than fatal, because an interrupted transfer can leave a torn line.
func CWD(path string) string {
	f, err := os.Open(path)
	if err != nil {
		return ""
	}
	defer f.Close()

	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 1024*1024), 64*1024*1024)
	for i := 0; i < 40 && sc.Scan(); i++ {
		var rec struct {
			CWD string `json:"cwd"`
		}
		if json.Unmarshal(sc.Bytes(), &rec) == nil && rec.CWD != "" {
			return rec.CWD
		}
	}
	return ""
}
