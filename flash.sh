#!/usr/bin/env bash
# Flash one example, or refuse to.
#
#   bash flash.sh target/thumbv8m.main-none-eabihf/release/examples/pac_led_blink            # dry run
#   bash flash.sh target/.../pac_led_blink --confirm                                        # writes
#
# The board carries the Gecko bootloader in 0x08000000-0x08005FFF. An image that lands there bricks it, so the first
# thing this script does is ask elf-load-range.py whether the image starts at 0x08006000 or above, and it refuses
# rather than warns. Everything else — the probe, the chip — is checked before anything is written.
set -euo pipefail

CHIP="${CHIP:-EFR32MG24B220F1536IM48}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ELF="${1:-}"
CONFIRM=0
[[ "${2:-}" == "--confirm" ]] && CONFIRM=1

if [[ -z "$ELF" || ! -f "$ELF" ]]; then
  printf 'usage: bash flash.sh <elf> [--confirm]\n' >&2
  exit 64
fi

printf '=== image\n'
if ! python3 "${HERE}/elf-load-range.py" "$ELF"; then
  printf '\nREFUSE: the image failed the address check above. Nothing was written.\n' >&2
  exit 1
fi

if ! command -v probe-rs >/dev/null 2>&1; then
  printf '\nREFUSE: probe-rs not found. Install it (cargo install probe-rs-tools), or flash with openocd and the same\n' >&2
  printf 'address check: the only thing this script does that a bare flash command does not is refuse a bad image.\n' >&2
  exit 1
fi

printf '\n=== probe\n'
if ! probe-rs list 2>/dev/null | grep -q .; then
  printf 'REFUSE: no debug probe visible. Connect the board and run this again.\n' >&2
  exit 1
fi
probe-rs list 2>/dev/null | sed 's/^/  /'

printf '\n=== target\n  chip=%s\n  elf=%s\n' "$CHIP" "$ELF"

if [[ "$CONFIRM" -ne 1 ]]; then
  printf '\nDRY RUN. Nothing was written. Re-run with --confirm to flash.\n'
  exit 0
fi

printf '\n=== writing\n'
probe-rs download --chip "$CHIP" "$ELF"
printf '\n=== verifying\n'
probe-rs verify --chip "$CHIP" "$ELF"
printf '\nDONE. The board is running the image above. If it is an example that writes a mailbox, read it back: written\n'
printf 'successfully is not the same as running.\n'
