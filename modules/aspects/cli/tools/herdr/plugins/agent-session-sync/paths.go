package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// Agent describes where one coding agent keeps its transcripts and how it
// encodes a project's working directory into a directory name.
type Agent struct {
	Name string
	Root string // relative to $HOME, same on both machines
}

var Agents = []Agent{
	{Name: "claude", Root: ".claude/projects"},
	{Name: "pi", Root: ".pi/agent/sessions"},
}

func agentByName(name string) (Agent, bool) {
	for _, a := range Agents {
		if a.Name == name {
			return a, true
		}
	}
	return Agent{}, false
}

// Slugify encodes an absolute path the way the agent does.
//
//	claude: /home/u/p/repo -> -home-u-p-repo
//	pi:     /home/u/p/repo -> --home-u-p-repo--
//
// Note this is not reversible: "/" and a literal "-" in a directory name both
// become "-", so a slug can never be parsed back into a path. Everything below
// therefore transforms slugs by prefix, and prefers the cwd recorded inside the
// transcript whenever one is available.
func Slugify(agent, path string) string {
	s := strings.ReplaceAll(path, "/", "-")
	if agent == "pi" {
		return "-" + s + "--"
	}
	return s
}

// PathMapping is one remote->local project path correspondence.
type PathMapping struct{ Remote, Local string }

// LoadMappings reads "<remote> <local>" pairs, one per line, "#" for comments.
// A leading "~" is expanded against the machine that side refers to.
func LoadMappings(file, remoteHome, localHome string) ([]PathMapping, error) {
	f, err := os.Open(file)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil // no mapping file is normal
		}
		return nil, err
	}
	defer f.Close()

	var out []PathMapping
	sc := bufio.NewScanner(f)
	for line := 1; sc.Scan(); line++ {
		text := strings.TrimSpace(sc.Text())
		if text == "" || strings.HasPrefix(text, "#") {
			continue
		}
		parts := strings.Fields(text)
		if len(parts) != 2 {
			return nil, fmt.Errorf("%s:%d: want '<remote> <local>', got %q", file, line, text)
		}
		out = append(out, PathMapping{
			Remote: expandTilde(strings.TrimRight(parts[0], "/"), remoteHome),
			Local:  expandTilde(strings.TrimRight(parts[1], "/"), localHome),
		})
	}
	return out, sc.Err()
}

func expandTilde(p, home string) string {
	if p == "~" {
		return home
	}
	if strings.HasPrefix(p, "~/") {
		return home + p[1:]
	}
	return p
}

// underPath reports whether path is prefix itself or lies beneath it. The
// boundary check is what stops /home/u from swallowing /home/username.
func underPath(path, prefix string) bool {
	return path == prefix || strings.HasPrefix(path, prefix+"/")
}

// RemapPath converts a remote absolute path to its local equivalent. Explicit
// mappings win over the home-prefix fallback, and the longest matching remote
// path wins so a specific repo can override a broader parent mapping. An
// unmapped path is returned unchanged, and mapped=false lets the caller warn.
func RemapPath(path, remoteHome, localHome string, maps []PathMapping) (local string, mapped bool) {
	best := -1
	for i, m := range maps {
		if underPath(path, m.Remote) && (best < 0 || len(m.Remote) > len(maps[best].Remote)) {
			best = i
		}
	}
	if best >= 0 {
		m := maps[best]
		return m.Local + strings.TrimPrefix(path, m.Remote), true
	}
	if underPath(path, remoteHome) {
		return localHome + strings.TrimPrefix(path, remoteHome), true
	}
	return path, false
}

// RemapSlug converts a remote session directory name to its local equivalent.
//
// When the transcript recorded its cwd, that absolute path goes through the
// full mapping table and is re-slugified — the accurate route. Otherwise it
// falls back to swapping the home prefix on the slug itself, which must match
// on a segment boundary for the same reason underPath exists.
func RemapSlug(agent, slug, cwd, remoteHome, localHome string, maps []PathMapping) (string, bool) {
	if cwd != "" {
		if lp, ok := RemapPath(cwd, remoteHome, localHome, maps); ok {
			return Slugify(agent, lp), true
		}
		return slug, false
	}

	rp, lp := Slugify(agent, remoteHome), Slugify(agent, localHome)
	if agent == "pi" {
		rp, lp = strings.TrimSuffix(rp, "--"), strings.TrimSuffix(lp, "--")
	}
	if slug == rp {
		return lp, true
	}
	if strings.HasPrefix(slug, rp+"-") {
		return lp + strings.TrimPrefix(slug, rp), true
	}
	return slug, false
}

// SessionUUID extracts the id used by `<agent> --resume`. pi prefixes the
// filename with a timestamp; a claude filename is the uuid itself.
func SessionUUID(agent, filename string) string {
	id := strings.TrimSuffix(filename, ".jsonl")
	if agent == "pi" {
		if i := strings.LastIndex(id, "_"); i >= 0 {
			return id[i+1:]
		}
	}
	return id
}
