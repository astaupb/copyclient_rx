include make.mk

.PHONY: format build deploy clean

format:
	dartfmt -w -l 100 --fix .

build: commit_ready
	flutter build apk

deploy: build
	mkdir -p out/android && mkdir -p out/ios
	cp build/app/outputs/apk/release/app-release.apk out/android/copyclient_${APP_VERSION}.apk
	tar czf app.tar.gz -C out/ android
	scp app.tar.gz root@shiva:/srv/www/dist/public/
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
