module gh
import os
import src.lc

const langtoext := {
    "cpp": "cpp",
    "java": "java",
    "python": "py",
    "python3": "py",
    "c": "c",
    "csharp": "cs",
    "javascript": "js",
    "typescript": "ts",
    "php": "php",
    "swift": "swift",
    "kotlin": "kt",
    "dart": "dart",
    "golang": "go",
    "scala": "scala",
    "rust": "rs",
    "ruby": "rb",
    "mysql": "sql",
    "mssql": "sql",
    "oraclesql": "sql",
    "bash": "sh",
    "racket": "rkt",
    "erlang": "erl",
    "elixir": "ex",
    "haskell": "hs",
    "perl": "pl",
    "lua": "lua",
    "clojure": "clj",
    "fsharp": "fs",
    "vb": "vb",
    "julia": "jl",
    "scheme": "scm",
    "groovy": "groovy",
    "pascal": "pas",
    "assembly": "asm"
}

/**
* Clones target remote repo into temporary directory.
*
* @param repoUrl URL to the GitHub repository
* @param pat personal access token
* @return full path to the temporary repo clone
*/
fn clone_tmp(repoUrl string, pat string) string {

    url_split := repoUrl.split("/")
    repo_name := url_split[url_split.len - 1]
    repo_owner := url_split[url_split.len - 2]

    root := os.temp_dir()
    path := os.join_path(root, repo_name)

    os.mkdir(path, os.MkdirParams{ mode : 0o777 }) or {}

    url_with_auth := "https://${pat}:x-oauth-basic@github.com/${repo_owner}/${repo_name}"

    println("Cloning repo...")
    os.execute("git clone ${url_with_auth} ${path}")

    return path
}

/**
* Takes in a Submission struct and outputs a string tuple with the submissions directory within the repo and its contents.
*
* @param path path in which the repo is temporarily stored in
* @param sub Submission struct
* @return string tuple containing file path and contents
*/
fn flatten_submission(path string, sub lc.Submission) (string, string, string) {

    sub_parent := os.join_path(path, "${sub.question_id:04} - ${sub.title}")
    sub_path := os.join_path(sub_parent, "${sub.title_slug}-${sub.timestamp}.${langtoext[sub.lang]}")
    sub_content := sub.code

    return sub_parent, sub_path, sub_content
}



/**
* Fetches accepted submissions and pushes changed files to GitHub remote repo.
*
* @param token csrftoken
* @param session leetcode_session
* @param path path of the temporary repo clone on system
*/
fn update_tmp(token string, session string, path string) {

    submissions := lc.get_accepted_submissions(token, session)

	mut readme_complete_slugs := []string{}

    for sub in submissions {

        sub_parent, sub_path, sub_content := flatten_submission(path, sub)

        os.mkdir(sub_parent, os.MkdirParams{ mode : 0o777 }) or {}
        os.write_file(sub_path, sub_content) or {panic("Failed to write file ${sub_path}.")}

        os.execute("git -C \"${path}\" add \"${sub_path}\"")
        os.execute("git -C \"${path}\" commit -m \"Runtime : ${sub.runtime} | Memory : ${sub.memory}\"")

		if !(sub.title_slug in readme_complete_slugs) {
			readme_complete_slugs << sub.title_slug

			mut readme := lc.get_problem_readme(token, session, sub.title_slug)
			readme = "# ${sub.question_id} | ${sub.title} \n" + readme
			readme_path := os.join_path(sub_parent, "README.md")

			println("Fetched problem description for `${sub.title}`")
			os.write_file(readme_path, readme) or {panic("Failed to write file ${readme_path}.")}
			os.execute("git -C \"${path}\" add \"${readme_path}\"")
			os.execute("git -C \"${path}\" commit -m \"Added problem README for ${sub.title_slug}\"")
		}
    }

    println("Pushing submissions to GitHub...")
    os.execute("git -C \"${path}\" push")
}

/**
* Recursively removes directory at path <path>. (Used to delete temporary repo clone)
*
* @param path path to delete
*/
fn close_tmp(path string) {
    os.rmdir_all(path) or {panic("Failed to delete ${path}")}
}

/**
* Synchronizes Leetcode submissions to GitHub
*
* @param token csrftoken
* @param session LEETCODE_SESSION
* @param repo_url url to the remote GitHub repo in which the submissions will  be pushed
* @param pat GitHub personal access token
*/
pub fn sync_submissions(token string, session string, repo_url string, pat string) {

    tmp_path := clone_tmp(repo_url, pat)
    update_tmp(token, session, tmp_path)
    close_tmp(tmp_path)
}
