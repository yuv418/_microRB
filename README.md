# _micro

_micro rewritten in Ruby.

**Note:** _microRB requires Ruby 2.7.

## Checklist: 

- [x] User and channel (server) notes
- [ ] Play media from ytdl supported sources (hopefully)
- [ ] Admin things (kick, ban)
- [ ] User rankings in server
- [ ] Snippets from websites (Wikipedia, EB, whatever)
- [ ] GaimBot support
- [ ] User role management

## Running

Copy the template config files to their names, minus `.template` and modify the variables inside each accordingly.
You will need MongoDB for the bot to function. There are plans to migrate to another DB that supports documents later.

```bash
bundle install
```

```bash
bundle exec ruby micro.rb
```

## Installing

Make sure you configured everything before doing this. 

**Note:** this only works on Linux with systemd at the moment.

First, copy the sample systemd service.

`cp microrb.service /etc/systemd/system/`

Then, modify the service you just copied with your preferred text editor to match the place and user which will run _microRB. Use your preferred text editor, for example:

`sudo nano /etc/systemd/system/microrb.service`

Finally, reload systemd and run the bot.

```bash
systemctl daemon-reload
systemctl start microrb
```


