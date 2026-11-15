# efr32mg2x-examples

Runnable examples for the XIAO MG24 Sense (EFR32MG24B220F1536IM48). Pull it from GitHub, build one, flash it.

```bash
git clone https://github.com/bitscrafts/efr32mg2x-examples
cd efr32mg2x-examples
rustup target add thumbv8m.main-none-eabihf

cargo build --release --examples -p pac-examples          # 27 examples, no dependencies beyond crates.io
cargo build --release --examples -p hal-examples          # 7
```

The image lands in `target/thumbv8m.main-none-eabihf/release/examples/<name>`. Flash it with the script, which
refuses a bad image instead of warning about it:

```bash
bash flash.sh target/thumbv8m.main-none-eabihf/release/examples/pac_led_blink            # dry run
bash flash.sh target/thumbv8m.main-none-eabihf/release/examples/pac_led_blink --confirm  # writes
```

```
load_min=0x08006000 load_max=0x08006377 size=888 segments=4
=== probe
  0d28:0204 DAPLink CMSIS-DAP (VID: 0x0d28, PID: 0x0204)
DRY RUN. Nothing was written. Re-run with --confirm to flash.
```

If you would rather use `probe-rs` directly, run the check first; it is the same script:

```bash
python3 elf-load-range.py target/thumbv8m.main-none-eabihf/release/examples/pac_led_blink   # rc=1 = do not flash
```

## Why GitHub and not crates.io

These were considered for crates.io as companion crates and rejected, for measured reasons: an examples-only crate has
no binary, so `cargo install <crate>` answers *"there is nothing to install … it has no binaries"* and only
`--example <name>` works; the `.cargo/config.toml` that fixes the target does not travel inside a `.crate`, so every
install needs `--target thumbv8m.main-none-eabihf` spelled out; and with no `lib.rs`, docs.rs has nothing to render, so
the crate page would be a README and nothing else. A clone is three commands and gives the whole set.

## One crate per layer

| crate | depends on | what it exercises | examples |
|---|---|---|---|
| `pac-examples` | `efr32mg2x-pac` from crates.io | registers by hand: clocks, GPIO, I2C, timers, ADC | 27 |
| `hal-examples` | `efr32mg2x-hal` from crates.io | the typed drivers on top of those registers | 7 |
| `radio-examples` | `efr32mg2x-radio` — needs the project tree | Bluetooth: advertising, scanning, GATT, diagnostics | 7 |
| `bsp-examples` | `efr32mg2x-xiao-bsp` — needs the project tree | the board itself: LED, button, IMU, microphone | 7 |
| `expansion-examples` | `efr32mg2x-expansion-base-bsp` — needs the project tree | the Expansion Base: OLED, BME680, buzzer, RTC, Grove | 10 |

The first two are workspace members and build from a plain clone. The other three are **excluded** from the workspace
because their dependencies point outside this repository: with a checkout of the main project beside this one they build
on their own (`cd radio-examples && cargo build --release --examples`), and a clone without it still builds the first
two instead of failing to resolve the workspace — which is exactly what happened before they were excluded.

## Flashing safely

Every image must load at or above `0x08006000`. The first 24 KiB of flash hold the Gecko bootloader; writing there
bricks the board. Check before you write, every time:

```bash
python3 elf-load-range.py target/thumbv8m.main-none-eabihf/release/examples/pac_led_blink
# load_min=0x08006000 load_max=0x08006377 size=888 segments=4
```

`load_min` below `0x08006000` is a refusal, not a warning.

## The trap that costs the first hour

A crate of your own built against the PAC fails to link with:

```
undefined symbol: _critical_section_1_0_acquire
```

The PAC exposes the `critical-section` feature; the *implementation* belongs to the architecture crate:

```toml
cortex-m = { version = "0.7", features = ["critical-section-single-core"] }
```

## Licence

MIT OR Apache-2.0.
