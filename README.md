## To get this running on M1 mac

- Add `127.0.0.1 host.docker.internal` to `/etc/hosts`
- Update docker to latest version and enable `Use Rosetta for x86/amd64 emulation on Apple Silicon` under experimental settings
- You may have to disable apple airplay in system settings if you find it is conflicting with .Stat runnning on port `7000`
