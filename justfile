default:
	@just --choose

# besu-logs: besu 컨테이너의 로그를 실시간으로 확인
besu-logs:
	#!/bin/bash

	# Docker 컨테이너 목록 중 이름에 "besu"가 포함된 컨테이너를 찾습니다.
	container_names=$(docker ps --format "{{{{.Names}}" | grep besu)

	# 각 besu 관련 컨테이너에 대해 반복합니다.
	for container_name in $container_names; do
	  # Zellij 세션을 새로 생성하여, 해당 컨테이너의 로그를 실시간으로 표시합니다.
	  # 로그 표시가 종료되면 5초 대기 후 다시 시도합니다.
	  zellij run -c -n "$container_name" -- bash -c "
	    while true; do
	      docker logs -f $container_name
	      sleep 5
	    done
	  "
	done

remove-logs:
	#!/bin/bash
	
	ps -ef | grep bash | grep while | grep "docker logs" | awk '{print $2}' | xargs kill

