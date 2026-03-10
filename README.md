# Orange Pi Apt Source Migration Script

Replaces the default Huawei Cloud (`repo.huaweicloud.com`) and Chinese university (`mirrors.ustc.edu.cn`, `mirrors.tuna.tsinghua.edu.cn`) apt mirrors that ship with Orange Pi's Debian-based OS with official upstream mirrors.

Tested on an **Orange Pi Zero 2W** running the stock Orange Pi OS (Debian Bullseye/armhf+arm64). Should work on other Orange Pi boards using the same base image.

## Why

Orange Pi OS ships with apt sources pointed at Huawei Cloud and Chinese university mirrors. These work fine in China but can be slow or unreliable elsewhere. This script switches them to the official Debian and Raspberry Pi Foundation mirrors.

## What It Does

The script modifies two files:

| File | Before | After |
|------|--------|-------|
| `/etc/apt/sources.list` | `repo.huaweicloud.com/debian` | `deb.debian.org/debian` |
| `/etc/apt/sources.list` | `repo.huaweicloud.com/debian-security` | `deb.debian.org/debian-security` |
| `/etc/apt/sources.list` | `*-backports` entries | `archive.debian.org/debian` (Bullseye backports are archived) |
| `/etc/apt/sources.list.d/raspi.list` | `mirrors.ustc.edu.cn` or `mirrors.tuna.tsinghua.edu.cn` | `archive.raspberrypi.org` |

It preserves the suite/codename (e.g. `bullseye`), all components (`main`, `contrib`, `non-free`), and any Orange Pi-specific repositories.

### Step by step

1. Detects the Debian codename from `/etc/os-release`
2. Displays current system info and apt sources
3. Creates timestamped backups (e.g. `sources.list.bak.20260309120000`)
4. Replaces mirror URLs via `sed` — skips any entries that are already official
5. Runs `apt update` to verify the new mirrors work

If `apt update` fails, the script exits with an error and tells you where the backups are.

## Usage

### Option A: Copy to the board and run locally

```bash
scp migrate-opi-sources.sh user@your-orange-pi:~
ssh user@your-orange-pi
sudo ./migrate-opi-sources.sh
```

### Option B: Pipe over SSH

```bash
ssh user@your-orange-pi 'sudo bash -s' < migrate-opi-sources.sh
```

### Option C: Download and run directly on the board

```bash
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/orange_pi_repository_migration_script/main/migrate-opi-sources.sh
chmod +x migrate-opi-sources.sh
sudo ./migrate-opi-sources.sh
```

The script requires root privileges and will exit immediately if not run with `sudo`.

## Reverting

The script creates timestamped backups before making any changes. To revert:

```bash
# Find your backups
ls /etc/apt/sources.list.bak.*
ls /etc/apt/sources.list.d/raspi.list.bak.*

# Restore (use the timestamp from your backup)
sudo cp /etc/apt/sources.list.bak.20260309120000 /etc/apt/sources.list
sudo cp /etc/apt/sources.list.d/raspi.list.bak.20260309120000 /etc/apt/sources.list.d/raspi.list
sudo apt update
```

## Compatibility

- **Tested on:** Orange Pi Zero 2W, Orange Pi OS (Debian 11 Bullseye)
- **Architecture:** aarch64 (arm64)
- **Requirements:** bash, sed, grep (all present in the stock image)
- **Idempotent:** Safe to run multiple times — skips entries that already point to official mirrors

Other Orange Pi boards (Zero 3, 5, 5 Plus, etc.) using the same Debian Bullseye base image should work identically. If your board ships with different mirror URLs not covered here, please open an issue.

## License

MIT
