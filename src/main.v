import json
import os

struct User {
mut:
    csrftoken string
    leetcode_session string
    remote_repo string
    pat string
}

const valid_keys = ['csrftoken', 'leetcode_session', 'remote_repo', 'pat']

fn config_dir() string {
    return os.join_path(
        os.config_dir() or {
            eprintln('Error: could not resolve config directory')
            exit(1)
        },
        'autolt'
    )
}

fn load_user() User {
    parent_dir := config_dir()
    user_json_path := os.join_path(parent_dir, 'user.json')

    if os.is_file(user_json_path) {
        data := os.read_file(user_json_path) or {
            eprintln('Error: failed to read user.json')
            exit(1)
        }
        return json.decode(User, data) or {
            eprintln('Error: corrupted user.json')
            exit(1)
        }
    }

    if !os.is_dir(parent_dir) {
        os.mkdir(parent_dir, os.MkdirParams{ mode: 0o777 }) or {
            eprintln('Error: failed to create config directory')
            exit(1)
        }
    }

    dummy := User{}
    os.write_file(user_json_path, json.encode(dummy)) or {
        eprintln('Error: failed to initialize user.json')
        exit(1)
    }

    return dummy
}

fn save_user(user User) {
    path := os.join_path(config_dir(), 'user.json')
    os.write_file(path, json.encode(user)) or {
        eprintln('Error: failed to save user configuration')
        exit(1)
    }
}

fn print_help() {
    println("
AutoLeet - LeetCode submission sync tool

  autolt sync                       Synchronize your LeetCode submissions to GitHub.
  autolt config                     Output current user configuaration keys and their values.
  autolt config <key> <value>       Set/Edit user configuration key <key> to value <value>.

    Available keys:

    csrftoken                         LeetCode's `csrftoken` value (Sourced from cookie).
    leetcode_session                  LeetCode's `LEETCODE_SESSION` value (Sourced from cookie).
    remote_repo                       URL to remote GitHub repo in which submissions will be pushed.
    pat                               GitHub generated Personal Access Token.

  autolt help                       Output list of supported commands.

NOTE: all configuration keys neet to be set and valid for successfully syncing.
")
}

fn run() {

    if os.args.len < 2 {
        eprintln('Error: missing command\n')
        print_help()
        exit(1)
    }

    mut user := load_user()
    get_problem_readme(user.csrftoken, user.leetcode_session, "add-two-numbers")

    cmd := os.args[1]

    match cmd {
        'sync' {
            mut missing := []string{}

            if user.csrftoken == '' { missing << 'csrftoken' }
            if user.leetcode_session == '' { missing << 'leetcode_session' }
            if user.remote_repo == '' { missing << 'remote_repo' }
            if user.pat == '' { missing << 'pat' }

            if missing.len > 0 {
                eprintln('Missing required configuration values:\n')
                for m in missing {
                    eprintln('  - $m')
                }
                eprintln('\nRun `autolt help` for setup instructions.')
                exit(1)
            }

            sync_submissions(
                user.csrftoken,
                user.leetcode_session,
                user.remote_repo,
                user.pat
            )
        }

        'config' {
            if os.args.len == 2 {
                println('Current configuration:\n')
                println('\tcsrftoken: ${user.csrftoken}')
                println('\tleetcode_session: ${user.leetcode_session}')
                println('\tremote_repo: ${user.remote_repo}')
                println('\tpat: ${user.pat}')
                return
            }

            if os.args.len != 4 {
                eprintln('Error: invalid number of arguments')
                print_help()
                exit(1)
            }

            key := os.args[2]
            value := os.args[3]

            if key !in valid_keys {
                eprintln('Error: invalid config key `$key`')
                exit(1)
            }

            match key {
                'csrftoken'        { user.csrftoken = value }
                'leetcode_session' { user.leetcode_session = value }
                'remote_repo'      { user.remote_repo = value }
                'pat'              { user.pat = value }
                else {}
            }

            println('Updated `$key` successfully.')
        }

        'help' {
            print_help()
            return
        }

        else {
            eprintln('Error: unknown command `$cmd`\n')
            print_help()
            exit(1)
        }
    }

    save_user(user)
}

fn main() {
    run()
}
