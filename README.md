# Monorepo for my Computer Craft projects

My favorite Minecraft mod is ComputerCraft (actually [CC: Tweaked][cct]). It's a
mod that adds programmable computers to the game.

[cct]: https://tweaked.cc

## About ComputerCraft

The mod is very simple yet very addictive, and I can spend hours writing code in
the game. Some people prefer using a real text editor and then import their code
in the game, but I find it extremely fun to do everything in the game itself,
starting from the built-in text editor and building my own tools to make it more
enjoyable to do as many things as possible inside of the game itself (or in
emulators). To make things even more fun, I forbid myself from using any code
written by other players (e.g. libraries, languages, programs...). The community
is amazing and people have created insane things, but writing everything myself
is how I personally enjoy this mod the most.

This naturally requires a lot of code to be written, so I ended up making my own
version of classic tools like `vi`, `tar`, `diff`, and even my own programming
language (Lua, the language used by the mod, is not statically typed, which
makes it a little difficult to work with in the long run). I also have some
Minecraft-specific programs, such as `mc` (MegaChest), `libnet` and `libtcp`
(not an actual TCP implementation, more on that further down).

## Typecraft & Craft

A lot of these are written in my own statically-typed programming language:
Typecraft. You can find the Typecraft compiler in `src/tcc`. Also, the `Recipe`
files are used by Craft (which you can find in `src/craft`) to build most
projects. It's a minimalistic build system that I made only for the purpose of
making it easier to build Typecraft projects (including the Typecraft compiler
itself). You can find builds (Lua) in `opt/*`.

## Disclaimer about names

These are all made for fun and educational purposes only. I have a lot of fun
recreating basic software utilities and components in Computer Craft. Because
naming things is hard, I decided to just name them after their real-world
equivalent.

However, they aren't necessarily clones of the real thing. `libtcp` does not
implement TCP, `vi` does not implement all `vi` features. Though, `tar` works
with real `tar` archives, and `vi` can read a very small subset of Vimscript to
support basic `.vimrc` files.

## Disclaimer about how I don't have time for this

I do all this for my own entertainment and education — by "working" on these, I
have learned a lot about `tar`, TCP/IP, `vi`/`vim`/`neovim`, compilers, etc...

But I don't want to _maintain_ this. I may or may not introduce breaking changes
to anything here. With or without any warning. I don't know, I don't care, and
neither should you because you shouldn't rely on this anyway. Except maybe for
educational purposes as well! Which is why I'm dedicating all this to the public
domain.

**I will not accept any contribution or bug report here.**
