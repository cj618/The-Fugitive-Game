# The Fugitive Game (CLI Alpha)

This is a content-light, system-complete CLI alpha for **Act I** of the narrative RPG. It covers 7 in-game days with a deterministic core loop, save/load, and basic logging.

## Requirements

* Perl 5.14+
* Modules: `JSON::PP`

Install optional dependencies with cpanm if needed:

```
cpanm --installdeps .
```

## Run

```
perl main.pl
```

## Tests

```
prove -l t
```

## Notes

* Save files are written to `saves/`.
* Logs are written to `logs/`.
* Act I alpha ends after Day 7 night or when law pressure reaches 100.
