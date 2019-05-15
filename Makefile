include make.mk

.PHONY: build deploy clean

build:
	flutter packages get && flutter build apk && flutter build ios

deploy: build
	mkdir -p out/android && mkdir -p out/ios
	cp build/app/outputs/apk/release/app-release.apk out/android/copyclient_${APP_VERSION}.apk
	cp -r build/ios/Release-iphoneos/Runner.app out/ios/Copyclient_${APP_VERSION}.app
	tar czf app.tar.gz -C out/ android ios
	scp app.tar.gz root@shiva:/srv/www/dist/public/
	rm app.tar.gz
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www/dist/public && mkdir -p android/current && mkdir -p ios/current" 
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www/dist/public && tar xzf app.tar.gz && rm app.tar.gz"
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www/dist/public && ln -sf /srv/www/dist/public/android/copyclient_${APP_VERSION}.apk android/current/copyclient.apk && ln -sf /srv/www/dist/public/ios/Copyclient_${APP_VERSION}.app ios/current/Copyclient.app" 
	rm -r out

clean:
	rm -rf build
