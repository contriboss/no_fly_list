.PHONY: up down restart ps test_all test_p test_m test_s

DB_ADAPTERS := postgresql mysql sqlite

up:
	docker-compose up -d

down:
	docker-compose down

ps:
	docker-compose ps

restart: down up

test_all:
	@status=0; \
	for adapter in $(DB_ADAPTERS); do \
		echo "Testing with $$adapter..."; \
		if ! DB_ADAPTER=$$adapter RAILS_ENV=test bin/rails db:drop db:create db:migrate; then \
			status=1; \
			continue; \
		fi; \
		if ! DB_ADAPTER=$$adapter RAILS_ENV=test bin/rails test; then \
			status=1; \
		fi; \
	done; \
	exit $$status

test_p:
	@echo "Testing with postgresql..."; \
	DB_ADAPTER=postgresql RAILS_ENV=test bin/rails db:drop db:create db:migrate; \
	DB_ADAPTER=postgresql RAILS_ENV=test bin/rails test;

test_m:
	@echo "Testing with mysql..."; \
	DB_ADAPTER=mysql RAILS_ENV=test bin/rails db:drop db:create db:migrate; \
	DB_ADAPTER=mysql RAILS_ENV=test bin/rails test;

test_s:
	@echo "Testing with sqlite..."; \
	DB_ADAPTER=sqlite RAILS_ENV=test bin/rails db:drop db:create db:migrate; \
	DB_ADAPTER=sqlite RAILS_ENV=test bin/rails test;
