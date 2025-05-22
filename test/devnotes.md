To Install mysql2 gem in the Mac Burger since i keep forgetting:
```bash
brew install mysql-client
gem install mysql2 -- --with-mysql-config=$(brew --prefix mysql-client)/bin/mysql_config
```
