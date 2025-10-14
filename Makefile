
default: up

docker-clean:
	docker stop $(docker ps -qa) && docker rm $(docker ps -qa) && docker volume rm $(docker volume ls -q) && docker network rm $(docker network ls -q)

up:
	docker-compose down
	docker-compose up --no-deps -d --build