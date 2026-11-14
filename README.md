# efr32mg2x-examples

Runnable examples for the XIAO MG24 Sense, **one crate per layer**, so that someone testing a given layer pulls that
layer and nothing else.

| crate | depends on | what it exercises | examples |
|---|---|---|---|
| `pac-examples` | `efr32mg2x-pac` from crates.io | registers, by hand: clocks, GPIO, I2C, timers, ADC | 27 |
| `hal-examples` | `efr32mg2x-hal` from crates.io | the typed drivers on top of those registers | 7 |
| `radio-examples` | `efr32mg2x-radio` (local path, not published) | Bluetooth: advertising, scanning, GATT, diagnostics | 7 |
| `bsp-examples` | `efr32mg2x-xiao-bsp` (local path) | the board itself: LED, button, IMU, microphone | 7 |
| `expansion-examples` | `efr32mg2x-expansion-base-bsp` (local path) | the Expansion Base: OLED, BME680, buzzer, RTC, Grove | 10 |

The first two crates resolve their dependencies from crates.io, so they are the two that a stranger can build with
nothing but this repository. The last three need the project tree, because the radio crate carries the vendor Bluetooth
and RAIL binaries and is not published yet — the path dependencies say so in place rather than hiding it.

## Building

The target is Cortex-M33 and the flags matter: `--nmagic` keeps the image to the single PT_LOAD segment the bootloader
expects.

```bash
rustup target add thumbv8m.main-none-eabihf

cargo build --release --examples -p pac-examples
cargo build --release --examples -p hal-examples
cargo build --release --examples -p radio-examples        # needs the project tree
cargo build --release --examples -p bsp-examples          # needs the project tree
cargo build --release --examples -p expansion-examples    # needs the project tree
```

## Flashing

Every image loads at or above `0x08006000`; the first 24 KiB belong to the bootloader and must never be written. Check
before you write, every time:

```bash
python3 elf-load-range.py target/thumbv8m.main-none-eabihf/release/examples/hal_led_blink
# load_min=0x08006000 ...   <- anything below this is a bricked board
```

## The trap that costs an hour

If you write your own crate against the PAC, the first build fails to link:

```
undefined symbol: _critical_section_1_0_acquire
```

The PAC exposes the `critical-section` feature, but the *implementation* belongs to the architecture crate:

```toml
cortex-m = { version = "0.7", features = ["critical-section-single-core"] }
```

## Layout

```
pac-examples/         Cargo.toml  memory.x  examples/*.rs  examples/common/
hal-examples/         ...
radio-examples/       ...
bsp-examples/         ...
expansion-examples/   ...
.cargo/config.toml    one target for the whole workspace
```

Each crate carries its own `memory.x`, because `cortex-m-rt` looks for it in the crate's own directory, not the
workspace root.

## Licence

MIT OR Apache-2.0.
