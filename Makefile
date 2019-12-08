include make.mk

.PHONY: format commit_ready build build_web deploy deploy_web clean

format:
	dartfmt -w -l 100 --fix .

build: commit_ready
	flutter build apk

build_web: commit_ready
	flutter build web

deploy_web: build_web
	tar czf app.tar.gz -C build web
	scp app.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:/srv/www/copyclient
	rm app.tar.gz
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www/copyclient && tar xzf app.tar.gz && rm app.tar.gz && rm -rf app && mv web app" 

deploy: build
	mkdir -p out/android && mkdir -p out/ios
	cp build/app/outputs/apk/release/app-release.apk out/android/copyclient_${APP_VERSION}.apk
	tar czf app.tar.gz -C out/ android
	scp app.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:/srv/www/dist/public/
	rm app.tar.gz
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www/dist/public && mkdir -p android/current" 
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www/dist/public && tar xzf app.tar.gz && rm app.tar.gz"
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www/dist/public && ln -sf /srv/www/dist/public/android/copyclient_${APP_VERSION}.apk android/current/copyclient.apk" 
	rm -r out

clean:
	rm -rf build

commit_ready: format
	git pull
	flutter packages get
	dartanalyzer --options analysis_options.yaml --lints lib
