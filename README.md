# Valkey lab with Docker Compose: learn a Redis-compatible key-value store, expiry, lists, hashes and counters

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-valkey/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-valkey/actions/workflows/check.yml)

A ready-made **Valkey lab** for classrooms, from the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), where schools and colleges give every student their own databases, containers and terminal in the browser. Each student gets their own **Valkey, the open source key-value store that speaks the same commands as Redis**, to learn **SET and GET, keys that expire, lists, hashes and counters**, and to see what a store that keeps data in memory does when it is stopped and started. Nothing is installed on the student's machine and nothing they type can affect anybody else.

It is one `docker-compose` file, `compose.yaml`, and it runs the same on your own machine as it does on the platform, where every student gets a private copy with no way out to the internet.

## What is in it

| Service | Image | Memory | What it is |
| --- | --- | --- | --- |
| `valkey` | [`valkey/valkey:8.1.10-alpine`](https://hub.docker.com/r/valkey/valkey) | 64 MB | the key-value store, on port 6379, with an append-only file in a named volume |

It starts healthy in about three seconds and uses roughly 4 MB when idle. It runs as an unprivileged user, and the most it will hold is 32 MB, after which a write is refused rather than the service being killed. There is no password, because nothing outside the copy can reach it.

The image is a third-party program, run unmodified from the project's own public image and pinned to a version (never `latest`), so the lab does not change under a class between one lesson and the next. Nothing is built here and nothing from this repository is distributed in it.

**Why Valkey and not Redis.** Valkey is the Linux Foundation's BSD-3-Clause fork of Redis 7.2, and it answers the same commands, so what a student learns here works on Redis and on most services that offer a Redis-compatible store. Redis 8 and later are licensed differently (AGPL or RSAL), which is why this lab uses Valkey.

## Using it on the platform

The [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning) gives every student their own copy of a lab, in the browser, with a terminal beside it.

**To try it:** open the [container page](https://mitsurutech.co.uk/container), find this lab in **Sample labs** and press Start, then **Open terminal**. No account is needed to try one. The lab has no web page, so everything is typed in the terminal.

**To set it as work for a class:**

1. In your module, make a task of type **Lab** and choose **In a GitHub repository**.
2. Give `https://github.com/mitsurutech/lab-valkey` with the branch `main`. The compose file is the default, `compose.yaml`. Fork the repository first if you want to change the file.
3. Publish. Every student's copy starts from the commit you published, so a later change here does not alter a lab already set.
4. Say in the task what to hand in (see [For teachers](#for-teachers)), and assign it like any other task.

The help manual's [page for this lab](https://mitsurutech.co.uk/help/lab-valkey) and its [guide to container labs](https://mitsurutech.co.uk/help/labs) cover the rest: what a compose file may say, how much memory a copy gets, and how a teacher opens, watches and marks a student's copy. There is also a free basic lesson, **Valkey Basics**, worked in this lab. No college account yet? [Your first year is free](https://mitsurutech.co.uk/pricing) for up to 50 students, and [signing up](https://mitsurutech.co.uk/signup) takes an email address.

## The terminal has no valkey-cli

The platform's terminal carries `psql`, `mariadb`, `curl`, `git` and `nc`, and not a Valkey client. That is no obstacle, because Valkey accepts a command as a line of plain text. This one line makes a function called `v` that sends its words to the store and prints the reply:

```bash
v() ( printf '%s\r\n' "$*" | nc -w 1 valkey 6379 )
```

Then:

```text
$ v SET greeting hello
+OK
$ v GET greeting
$5
hello
$ v GET missing
$-1
```

The replies are the real protocol, **RESP**: `+` is a short success word, `$5` says the next line is a text of five bytes, `$-1` is "nothing there", `:3` is a number and `*3` says three items follow. You can also run `nc valkey 6379` and type commands straight at the server, one per line. On your own machine you can use `valkey-cli` or `redis-cli` instead, see below.

## Running it on your own machine

You need Docker with the Compose plugin. The first start downloads the image.

```bash
docker compose -f compose.yaml -f local.yaml up
```

`local.yaml` publishes port 6379 on `127.0.0.1` only, so the lab is reachable from your own computer and from nowhere else. Connect with `valkey-cli -p 6379` or `redis-cli -p 6379`, or with `nc` as above. Stop it with `Ctrl-C`, and remove it, data included, with `docker compose -f compose.yaml -f local.yaml down -v`.

## Working through it

1. **Store and fetch.** `v SET greeting hello`, then `v GET greeting`.
2. **Make a key expire.** `v SET code 1234 EX 5` stores it for five seconds. `v TTL code` counts down, and after the five seconds `v GET code` answers `$-1`.
3. **A list.** `v RPUSH tasks wake eat code` answers `:3`, and `v LRANGE tasks 0 -1` reads the three back in order.
4. **A hash.** `v HSET user:1 name Ada born 1815` answers `:2`, and `v HGETALL user:1` prints the field names and values.
5. **A counter.** `v INCR visits` answers `:1`, and again `:2`. The store does the adding, so two clients at once never lose a count.
6. **See what lasts.** Stop the lab and start it again: `v GET greeting` is still `hello`. The store keeps everything in memory, which is why it is fast, and logs every write to an append-only file in a named volume, which is how it rebuilds its memory on start. `v CONFIG GET appendonly` answers `yes`. The expired key has not come back.

## For teachers

Nothing in this lab is marked automatically. The student hands in evidence and you mark it, the way you mark any other lab.

**Ask for the replies of a short session of their own:** a key with an expiry and `TTL` counting down, a list, a hash and a counter, with a sentence on what the expiry did, and one on what was still there after they stopped and started the lab and why. The last one shows whether they understood memory against a file on disk.

**Where it sits in a course.** It suits an introduction to databases and data stores, where a key-value store is the simplest of the non-relational kinds, and to web development, where sessions, caches and counters are what such a store is used for. Check your own awarding body's unit for the exact wording; none is quoted here.

**Who sees what.** A copy is private to the student who started it. A member of staff who teaches the module can open it to see what the student has done, and opening a student's work is written to the access log, which the student can read.

## What does not work in a lab

The lab has no way out to the internet, no password on the store (nothing else can reach it) and no web page. Other Valkey features, such as replication to a second server, need more than one service and are not part of this lab. The store is given 64 MB and refuses writes past 32 MB of data.

## Troubleshooting

- **A command prints nothing.** Define the `v` function first, in the same terminal. If the store has not started, wait until the lab says it is running.
- **A reply looks like `$5`.** That is the length of the next line, not an error: read the line after it.
- **On your own machine, port 6379 is already in use.** Change the left-hand number in `local.yaml`, for example `127.0.0.1:6380:6379`.

## Checking the lab

`test/check.sh` starts the lab the way the platform's runner starts every service (all capabilities dropped, `no-new-privileges`, a process limit, memory limits, and no way out to the internet) and then checks from inside its network what this page promises: the commands above answer as shown, an expiry runs out, and a key written before a stop is still there after the start. It needs Docker and runs on every push, which is the badge at the top.

```bash
test/check.sh
```

## Versions and licences

[Valkey](https://valkey.io) is BSD-3-Clause licensed. The image is `valkey/valkey:8.1.10-alpine`, run unmodified and not distributed by us.

The application inside is the licence of its own project, linked above.

## Licence

This work is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). You may share it and adapt it for learning and teaching, if you credit Mitsuru Technologies Ltd, do not use it commercially, and share anything you make from it under the same licence. The full text is in the `LICENSE` file.

## About

Made by [Mitsuru Technologies](https://mitsurutech.co.uk) for the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL and Linux in the browser for schools and colleges, with container labs, web apps deployed from GitHub, and quizzes that mark themselves. Try code with no account in the [playground](https://mitsurutech.co.uk/playground). All the labs are listed in the [manual](https://mitsurutech.co.uk/help/labs).

More labs from the same place: [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea), [lab-observability](https://github.com/mitsurutech/lab-observability), [lab-dvwa](https://github.com/mitsurutech/lab-dvwa) and [lab-sample](https://github.com/mitsurutech/lab-sample).
