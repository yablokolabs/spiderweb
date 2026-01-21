# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test.nim - Test file for spiderweb validation

proc greet(name: string) =
  echo "Hi ", name

proc main() =
  greet("world")
  greet("nim")

when isMainModule:
  main()
