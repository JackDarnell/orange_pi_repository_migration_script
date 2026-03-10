# Orange Pi Apt Source Migration

Switches the stock Orange Pi OS apt mirrors from Huawei Cloud and Chinese university mirrors to official Debian and Raspberry Pi Foundation infrastructure.

| Mirror | Before | After |
|--------|--------|-------|
| Debian | `repo.huaweicloud.com` | `deb.debian.org` |
| Debian Security | `repo.huaweicloud.com` | `deb.debian.org` |
| Debian Backports | `repo.huaweicloud.com` | `archive.debian.org` |
| Raspbian | `mirrors.ustc.edu.cn` / `mirrors.tuna.tsinghua.edu.cn` | `archive.raspberrypi.org` |

The script auto-detects the codename, preserves all components, creates timestamped backups, and runs `apt update` to verify.

## Usage

```bash
# On the Orange Pi
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/orange_pi_repository_migration_script/main/migrate-opi-sources.sh
chmod +x migrate-opi-sources.sh
sudo ./migrate-opi-sources.sh
```

Or remotely:

```bash
ssh user@your-orange-pi 'sudo bash -s' < migrate-opi-sources.sh
```

Requires root. Safe to run multiple times.

## Reverting

Backups are saved as `sources.list.bak.<timestamp>`. To restore:

```bash
sudo cp /etc/apt/sources.list.bak.TIMESTAMP /etc/apt/sources.list
sudo cp /etc/apt/sources.list.d/raspi.list.bak.TIMESTAMP /etc/apt/sources.list.d/raspi.list
sudo apt update
```

## Compatibility

Tested on Orange Pi Zero 2W (Debian 11 Bullseye, aarch64). Should work on other Orange Pi boards using the same base image (Zero 3, 5, 5 Plus, etc.).

## License

MIT
