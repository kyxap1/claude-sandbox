#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../claude-sandbox"
  TEST_TMPDIR=$(mktemp -d)
  mkdir -p "$TEST_TMPDIR/repo-a" "$TEST_TMPDIR/repo-b"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# stub docker to capture args
docker() { echo "$@"; }
export -f docker

@test "no args: runs docker with base mounts only" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--cap-add NET_ADMIN"* ]]
  [[ "$output" == *"--cap-add NET_RAW"* ]]
  [[ "$output" == *"kyxap/claude-sandbox"* ]]
  [[ "$output" != *"/mnt/"* ]]
}

@test "claude args pass through" {
  run bash "$SCRIPT" -p "hello"
  [ "$status" -eq 0 ]
  [[ "$output" == *"-p hello"* ]]
}

@test "-v mounts directory into /mnt/<basename>" {
  run bash "$SCRIPT" -v "$TEST_TMPDIR/repo-a"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$TEST_TMPDIR/repo-a:/mnt/repo-a"* ]]
}

@test "multiple -v flags" {
  run bash "$SCRIPT" -v "$TEST_TMPDIR/repo-a" -v "$TEST_TMPDIR/repo-b"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/mnt/repo-a"* ]]
  [[ "$output" == *"/mnt/repo-b"* ]]
}

@test "-v with claude args" {
  run bash "$SCRIPT" -v "$TEST_TMPDIR/repo-a" -p "fix bug"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/mnt/repo-a"* ]]
  [[ "$output" == *"-p fix bug"* ]]
}

@test "-v with nonexistent dir fails" {
  run bash "$SCRIPT" -v "$TEST_TMPDIR/nope"
  [ "$status" -ne 0 ]
}

@test "--continue passes through" {
  run bash "$SCRIPT" --continue
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kyxap/claude-sandbox --continue" ]]
}

@test "--resume passes through" {
  run bash "$SCRIPT" --resume
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kyxap/claude-sandbox --resume" ]]
}

@test "-v with --continue" {
  run bash "$SCRIPT" -v "$TEST_TMPDIR/repo-a" --continue
  [ "$status" -eq 0 ]
  [[ "$output" =~ "/mnt/repo-a" ]]
  [[ "$output" =~ "kyxap/claude-sandbox --continue" ]]
}

@test "SANDBOX_FIREWALL passes through to docker" {
  SANDBOX_FIREWALL=false run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SANDBOX_FIREWALL=false"* ]]
}

@test "SANDBOX_FIREWALL defaults to true" {
  unset SANDBOX_FIREWALL
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SANDBOX_FIREWALL=true"* ]]
}

@test "mounts ~/.claude.json into container" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *".claude.json:/home/node/.claude.json"* ]]
}

@test "creates ~/.claude.json if missing" {
  HOME="$TEST_TMPDIR" run bash "$SCRIPT"
  [ -f "$TEST_TMPDIR/.claude.json" ]
}
