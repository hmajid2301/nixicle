package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/mattn/go-sqlite3"
)

var home string

func init() {
	home, _ = os.UserHomeDir()
}

func writeFishHistoryFile(t int, cmd string) {
	file, err := os.OpenFile(home+"/.local/share/fish/fish_history", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	content := fmt.Sprintf("- cmd: %s\n  when: %d\n", cmd, t/1000000000)

	_, err = file.WriteString(content)
	if err != nil {
		panic(err)
	}
}

func main() {
	db, err := sql.Open("sqlite3", home+"/.local/share/atuin/history.db")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()

	rows, err := db.Query("SELECT * FROM history ORDER BY timestamp ASC")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var id, command, cwd, session, hostname string
		var timestamp, duration, exit int
		var deleted_at interface{}

		err = rows.Scan(&id, &timestamp, &duration, &exit, &command, &cwd, &session, &hostname, &deleted_at)
		if err != nil {
			fmt.Println(err)
			continue
		}

		writeFishHistoryFile(timestamp, command)
	}

	err = rows.Err()
	if err != nil {
		fmt.Println(err)
		return
	}
}
