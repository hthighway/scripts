These systemd files will lauch plexdrive and then create a UNIONFS merging a local and remote folder

See https://github.com/dweidenfeld/plexdrive for instructions on how to initally setup PLEXDRIVE

See: https://www.devmanuals.net/install/ubuntu/ubuntu-16-04-LTS-Xenial-Xerus/how-to-install-unionfs-fuse.html for info on installing UnionFS-fuse on linux (Ubuntu 16.04)


```
sudo touch /etc/systemd/system/plexdrive.service
sudo nano /etc/systemd/system/plexdrive.service
```
> paste content of plexdrive.service here
```
sudo systemctl enable plexdrive.service
sudo systemctl start plexdrive
```
```
sudo touch /etc/systemd/system/plexunion.service
sudo nano /etc/systemd/system/plexunion.service
```
> paste content of plexunion.service here
```
sudo systemctl enable plexunion.service
sudo systemctl start plexunion
```

# Additional Notes:

if you use other services that will connect to the mount (Plex, Sonarr, Radarr) consider modifying the service file for those and setting the `After=` value to `After=plexunion.service`.

Every little bit helps: https://paypal.me/pwhdesigns
