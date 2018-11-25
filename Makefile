K       ?= K.sh
MAJOR    = 0
MINOR    = 4
PATCH    = 11
BUILD    = 2
SOURCE   = hello-world \
           trading-bot
CARCH    = x86_64-linux-gnu      \
           arm-linux-gnueabihf   \
           aarch64-linux-gnu     \
           x86_64-apple-darwin17 \
           x86_64-w64-mingw32

CHOST   ?= $(shell (test -d .git && test -n "`command -v g++`") && g++ -dumpmachine \
             || echo $(subst build-,,$(firstword $(wildcard build-*))))
KLOCAL  := build-$(CHOST)/local

ERR      = *** K require g++ v7 or greater, but it was not found.
HINT    := consider a symlink at /usr/bin/$(CHOST)-g++ pointing to your g++-7 or g++-8 executable

STEP     = $(shell tput setaf 2;tput setab 0)Building $(1)..$(shell tput sgr0)
KARGS   := -pthread -std=c++17 -O3 -DK_BUILD='"$(CHOST)"' \
  -DK_SOURCE='"K-$(KSRC)"' -DK_0_GIT='"$(shell            \
  cat .git/refs/heads/master 2>/dev/null || echo HEAD)"'  \
  -DK_STAMP='"$(shell date "+%Y-%m-%d %H:%M:%S")"'        \
  -DK_0_DAY='"v$(MAJOR).$(MINOR).$(PATCH)+$(BUILD)"'      \
  -I$(realpath $(KLOCAL)/../../src/include)               \
  -I$(KLOCAL)/include        $(KLOCAL)/include/uWS/*.cpp  \
  $(KLOCAL)/lib/K-$(CHOST).a $(KLOCAL)/lib/libquickfix.a  \
  $(KLOCAL)/lib/libsqlite3.a $(KLOCAL)/lib/libz.a         \
  $(KLOCAL)/lib/libcurl.a    $(KLOCAL)/lib/libssl.a       \
  $(KLOCAL)/lib/libcrypto.a  $(KLOCAL)/lib/libncurses.a   \
  $(wildcard                                              \
    $(KLOCAL)/lib/lib*.dll.a                              \
    $(KLOCAL)/lib/libcares.a                              \
    $(KLOCAL)/lib/libuv.a                                 \
    $(KLOCAL)/lib/K-$(KSRC)-assets.o                      \
  )

all K: $(SOURCE)

hlep hepl help:
	#                                                  #
	# Available commands inside K top level directory: #
	#  make help         - show this help              #
	#                                                  #
	#  make              - compile K sources           #
	#  make K            - compile K sources           #
	#  KALL=1 make K     - compile K sources           #
	#  make trading-bot  - compile K sources           #
	#                                                  #
	#  make dist         - compile K dependencies      #
	#  KALL=1 make dist  - compile K dependencies      #
	#  make packages     - provide K dependencies      #
	#  make install      - install K application       #
	#  make docker       - install K application       #
	#  make reinstall    - upgrade K application       #
	#  make doc          - compile K documentation     #
	#  make test         - run tests                   #
	#  make test-c       - run static tests            #
	#                                                  #
	#  make list         - show K instances            #
	#  make start        - start K instance            #
	#  make startall     - start K instances           #
	#  make stop         - stop K instance             #
	#  make stopall      - stop K instances            #
	#  make restart      - restart K instance          #
	#  make restartall   - restart K instances         #
	#                                                  #
	#  make diff         - show commits and versions   #
	#  make changelog    - show commits                #
	#  make latest       - show commits and reinstall  #
	#                                                  #
	#  make download     - download K src precompiled  #
	#  make clean        - remove external src files   #
	#  KALL=1 make clean - remove external src files   #
	#  make cleandb      - remove databases            #
	#  make uninstall    - remove /usr/local/bin/K-*   #
	#                                                  #

doc test:
	@$(MAKE) -sC $@

clean dist:
ifdef KALL
	unset KALL $(foreach chost,$(CARCH),&& $(MAKE) $@ CHOST=$(chost))
else
	$(if $(subst 8,,$(subst 7,,$(shell $(CHOST)-g++ -dumpversion | cut -d. -f1))),$(warning $(ERR));$(error $(HINT)))
	@$(MAKE) -C src/include $@ CHOST=$(CHOST)
endif

$(SOURCE):
	$(info $(call STEP,$@))
	$(MAKE) $(shell ! test -f src/$@/Makefile || echo assets) src KSRC=$@

assets: src/$(KSRC)/Makefile
	$(info $(call STEP,$(KSRC) $@))
	$(MAKE) -C src/$(KSRC) KASSETS=$(abspath $(KLOCAL)/assets)
	$(foreach chost,$(subst $(CHOST),,$(CARCH)) $(CHOST),      \
	  ! test -d build-$(chost)                                 \
	  || ((test -d build-$(chost)/local/assets                 \
	    || cp -R $(KLOCAL)/assets build-$(chost)/local/assets) \
	  && $(MAKE) assets.o CHOST=$(chost)                       \
	  && rm -rf build-$(chost)/local/assets)                   \
	;)

assets.o: src/$(KSRC)/$(KSRC).S
	$(CHOST)-g++ -Wa,-I,$(KLOCAL)/assets,-I,src/$(KSRC) -c $^ \
	  -o $(KLOCAL)/lib/K-$(notdir $(basename $^))-$@

src: src/$(KSRC)/$(KSRC).cxx
ifdef KALL
	unset KALL $(foreach chost,$(CARCH),&& $(MAKE) $@ CHOST=$(chost))
else
	$(info $(call STEP,$(KSRC) $@ $(CHOST)))
	$(if $(subst 8,,$(subst 7,,$(shell $(CHOST)-g++ -dumpversion | cut -d. -f1))),$(warning $(ERR));$(error $(HINT)))
	@$(CHOST)-g++ --version
	@mkdir -p $(KLOCAL)/bin
	-@egrep ฿ src test -lR --exclude-dir=node_modules | xargs sed -i 's/฿/\\u0E3F/'
	$(MAKE) $(shell test -n "`echo $(CHOST) | grep darwin`" && echo Darwin || (test -n "`echo $(CHOST) | grep mingw32`" && echo Win32 || uname -s)) CHOST=$(CHOST)
	-@egrep \\u0E3F src test -lR --exclude-dir=node_modules | xargs sed -i 's/\\u0E3F/฿/'
	@chmod +x $(KLOCAL)/bin/K-$(KSRC)*
	@$(MAKE) system_install -s
endif

Linux: src/$(KSRC)/$(KSRC).cxx
ifdef KUNITS
	@unset KUNITS && $(MAKE) KTEST="--coverage test/unit_testing_framework.cxx" $@
else ifndef KTEST
	@$(MAKE) KTEST="-DNDEBUG" $@
else
	$(CHOST)-g++ $(KTEST) -o $(KLOCAL)/bin/K-$(KSRC) \
	  -DHAVE_STD_UNIQUE_PTR -DUWS_THREADSAFE         \
	  -static-libstdc++ -static-libgcc -rdynamic     \
	  $^ $(KARGS) -ldl
endif

Darwin: src/$(KSRC)/$(KSRC).cxx
	-@egrep \\u0E3F src -lR --exclude-dir=node_modules | xargs sed -i 's/\\\(u0E3F\)/\1/'
	$(CHOST)-g++ -DNDEBUG -o $(KLOCAL)/bin/K-$(KSRC)                             \
	  -DUSE_LIBUV                                                                \
	  -msse4.1 -maes -mpclmul -mmacosx-version-min=10.13 -nostartfiles -rdynamic \
	  $^ $(KARGS) -ldl
	-@egrep u0E3F src -lR --exclude-dir=node_modules | xargs sed -i 's/\(u0E3F\)/\\\1/'

Win32: src/$(KSRC)/$(KSRC).cxx
	$(CHOST)-g++-posix -DNDEBUG -o $(KLOCAL)/bin/K-$(KSRC).exe   \
	  -DUSE_LIBUV -D_POSIX -DCURL_STATICLIB                      \
	  $^ $(KARGS)                                                \
	  -static -lstdc++ -lgcc -lwldap32 -lws2_32

download:
	curl -L https://github.com/ctubio/Krypto-trading-bot/releases/download/$(MAJOR).$(MINOR).x/v$(MAJOR).$(MINOR).$(PATCH).$(BUILD)-$(CHOST).tar.gz | tar xz
	@$(MAKE) system_install -s
	@ln -f -s /usr/local/bin/K-trading-bot app/server/K
	@test -n "`ls *.sh 2>/dev/null`" || (cp etc/K.sh.dist K.sh && chmod +x K.sh)

cleandb: /data/db/K*
	rm -rf /data/db/K*.db

packages:
	test -n "`command -v apt-get`" && sudo apt-get -y install g++ build-essential automake autoconf libtool libxml2 libxml2-dev zlib1g-dev openssl python curl gzip screen doxygen graphviz \
	|| (test -n "`command -v yum`" && sudo yum -y install gcc-c++ automake autoconf libtool libxml2 libxml2-devel openssl python curl gzip screen) \
	|| (test -n "`command -v brew`" && (xcode-select --install || :) && (brew install automake autoconf libxml2 sqlite openssl zlib python curl gzip proctools doxygen graphviz || brew upgrade || :)) \
	|| (test -n "`command -v pacman`" && sudo pacman --noconfirm -S --needed base-devel libxml2 zlib sqlite curl libcurl-compat openssl python gzip screen)

uninstall:
	@$(foreach bin,$(addprefix /usr/local/bin/,$(notdir $(wildcard $(KLOCAL)/bin/K-*))), sudo rm -v $(bin);)

system_install:
	$(info Checking sudo permission to install binaries into /usr/local/bin.. $(shell sudo echo OK))
	$(info Checking if /usr/local/bin is already in your PATH.. $(if $(shell echo $$PATH | grep /usr/local/bin),OK))
	$(if $(shell echo $$PATH | grep /usr/local/bin),,$(info $(subst ..,,$(subst Building ,,$(call STEP,Warning! you MUST add /usr/local/bin to your PATH!)))))
	$(info Checking if /etc/ssl/certs is readable by curl.. $(shell (test -d /etc/ssl/certs && echo OK) || (sudo mkdir -p /etc/ssl/certs && echo OK)))
	$(info Checking if /data/db is writable by sqlite.. $(shell (test -d /data/db && echo OK) || (sudo mkdir -p /data/db && sudo chown $(shell id -u) /data/db && echo OK)))
	$(info )
	$(info List of installed K binaries:)
	@sudo cp -f $(wildcard $(KLOCAL)/bin/K-$(KSRC)*) /usr/local/bin
	@LS_COLORS="ex=40;92" CLICOLOR="Yes" ls $(shell ls --color > /dev/null 2>&1 && echo --color) -lah $(addprefix /usr/local/bin/,$(notdir $(wildcard $(KLOCAL)/bin/K-$(KSRC)*)))
	@echo
	@sudo curl -s --time-cond /etc/ssl/certs/ca-certificates.crt https://curl.haxx.se/ca/cacert.pem \
	  -o /etc/ssl/certs/ca-certificates.crt

install:
	@$(MAKE) packages
	mkdir -p app/server
	@yes = | head -n`expr $(shell tput cols) / 2` | xargs echo && echo " _  __\n| |/ /\n| ' /   Select your (beloved) architecture\n| . \\   to download pre-compiled binaries:\n|_|\\_\\ \n"
	@echo $(CARCH) | tr ' ' "\n" | cat -n && echo "\n(Hint! uname says \"`uname -sm`\", and win32 auto-install does not work yet)\n"
	@read -p "[1/2/3/4/5]: " chost && $(MAKE) download CHOST=`echo $(CARCH) | cut -d ' ' -f$${chost}`

docker:
	@$(MAKE) packages
	mkdir -p app/server
	@$(MAKE) download
	sed -i "/Usage/,+118d" K.sh

reinstall:
	test -d .git && ((test -n "`git diff`" && (echo && echo !!Local changes will be lost!! press CTRL-C to abort. && echo && sleep 5) || :) \
	&& git fetch && git merge FETCH_HEAD || (git reset FETCH_HEAD && git checkout .)) || curl https://raw.githubusercontent.com/ctubio/Krypto-trading-bot/master/Makefile > Makefile
	rm -rf app
	@$(MAKE) install
	#@$(MAKE) restartall
	@echo && echo ..done! Please restart any running instance and also refresh the UI if is currently opened in your browser.

list:
	@screen -list || :

restartall:
	@$(MAKE) stopall -s
	@sleep 3
	@$(MAKE) startall -s
	@$(MAKE) list -s

stopall:
	ls -1 *.sh | cut -d / -f2 | cut -d \* -f1 | grep -v ^_ | xargs -I % $(MAKE) K=% stop -s

startall:
	ls -1 *.sh | cut -d / -f2 | cut -d \* -f1 | grep -v ^_ | xargs -I % sh -c 'sleep 2;$(MAKE) K=% start -s'
	@$(MAKE) list -s

restart:
	@$(MAKE) stop -s
	@sleep 3
	@$(MAKE) start -s
	@$(MAKE) list -s

stop:
	@screen -XS $(K) quit && echo STOP $(K) DONE || :

start:
	@test -d app || $(MAKE) install
	@test -n "`screen -list | grep "\.$(K)	("`"         \
	&& (echo $(K) is already running.. && screen -list)  \
	|| (screen -dmS $(K) ./$(K) && echo START $(K) DONE)

screen:
	@test -n "`screen -list | grep "\.$(K)	("`" && (    \
	echo Detach screen hotkey: holding CTRL hit A then D \
	&& sleep 2 && screen -r $(K)) || screen -list || :

diff: .git
	@_() { echo $$2 $$3 version: `git rev-parse $$1`; }; git remote update && _ @ Local running && _ @{u} Latest remote
	@$(MAKE) changelog -s

latest: .git diff
	@_() { git rev-parse $$1; }; test `_ @` != `_ @{u}` && $(MAKE) reinstall || :

changelog: .git
	@_() { echo `git rev-parse $$1`; }; echo && git --no-pager log --graph --oneline @..@{u} && test `_ @` != `_ @{u}` || echo No need to upgrade, both versions are equal.

test-c:
ifndef KSRC
	@$(foreach src,$(SOURCE),$(MAKE) -s $@ KSRC=$(src);)
else
	@cp test/static_code_analysis.cxx test/static_code_analysis-$(KSRC).cxx
	@sed -i "s/%/$(KSRC)/g" test/static_code_analysis-$(KSRC).cxx
	@pvs-studio-analyzer analyze -e test/units.h -e $(KLOCAL)/include --source-file test/static_code_analysis-$(KSRC).cxx --cl-params -I. -Isrc/include -I$(KLOCAL)/include test/static_code_analysis-$(KSRC).cxx && \
	(plog-converter -a GA:1,2 -t tasklist -o report.tasks PVS-Studio.log && cat report.tasks && rm report.tasks) || :
	@rm PVS-Studio.log test/static_code_analysis-$(KSRC).cxx
endif

#png: etc/${PNG}.png etc/${PNG}.json
#	convert etc/${PNG}.png -set "K.conf" "`cat etc/${PNG}.json`" K: etc/${PNG}.png 2>/dev/null || :
#	@$(MAKE) png-check -s

#png-check: etc/${PNG}.png
#	@test -n "`identify -verbose etc/${PNG}.png | grep 'K\.conf'`" && echo Configuration injected into etc/${PNG}.png OK, feel free to remove etc/${PNG}.json anytime. || echo nope, injection failed.

checkOK:
	@date=`date` && git diff && git status && read -p "KMOD: " KMOD     \
	&& git add . && git commit -S -m "$${KMOD}"                         \
	&& ((KALL=1 $(MAKE) K doc release && git push) || git reset HEAD^1) \
	&& echo $${date} && date

MAJOR:
	@sed -i "s/^\(MAJOR    =\).*$$/\1 $(shell expr $(MAJOR) + 1)/" Makefile
	@sed -i "s/^\(MINOR    =\).*$$/\1 0/" Makefile
	@sed -i "s/^\(PATCH    =\).*$$/\1 0/" Makefile
	@sed -i "s/^\(BUILD    =\).*$$/\1 0/" Makefile
	@$(MAKE) checkOK

MINOR:
	@sed -i "s/^\(MINOR    =\).*$$/\1 $(shell expr $(MINOR) + 1)/" Makefile
	@sed -i "s/^\(PATCH    =\).*$$/\1 0/" Makefile
	@sed -i "s/^\(BUILD    =\).*$$/\1 0/" Makefile
	@$(MAKE) checkOK

PATCH:
	@sed -i "s/^\(PATCH    =\).*$$/\1 $(shell expr $(PATCH) + 1)/" Makefile
	@sed -i "s/^\(BUILD    =\).*$$/\1 0/" Makefile
	@$(MAKE) checkOK

BUILD:
	@sed -i "s/^\(BUILD    =\).*$$/\1 $(shell expr $(BUILD) + 1)/" Makefile
	@$(MAKE) checkOK

release:
ifdef KALL
	unset KALL $(foreach chost,$(CARCH),&& $(MAKE) $@ CHOST=$(chost))
else
	@tar -cvzf v$(MAJOR).$(MINOR).$(PATCH).$(BUILD)-$(CHOST).tar.gz $(KLOCAL)/bin/K-* $(KLOCAL)/lib/K-*                                   \
	$(shell test -n "`echo $(CHOST) | grep mingw32`" && echo $(KLOCAL)/bin/*dll || :)                                                     \
	LICENSE COPYING README.md Makefile doc/[^html]* etc test --exclude src/*/node_modules src                                             \
	&& curl -s -n -H "Content-Type:application/octet-stream" -H "Authorization: token ${KRELEASE}"                                        \
	--data-binary "@$(PWD)/v$(MAJOR).$(MINOR).$(PATCH).$(BUILD)-$(CHOST).tar.gz"                                                          \
	"https://uploads.github.com/repos/ctubio/Krypto-trading-bot/releases/$(shell curl -s                                                  \
	https://api.github.com/repos/ctubio/Krypto-trading-bot/releases/latest | grep id | head -n1 | cut -d ' ' -f4 | cut -d ',' -f1         \
	)/assets?name=v$(MAJOR).$(MINOR).$(PATCH).$(BUILD)-$(CHOST).tar.gz"                                                                   \
	&& rm v$(MAJOR).$(MINOR).$(PATCH).$(BUILD)-$(CHOST).tar.gz && echo && echo DONE v$(MAJOR).$(MINOR).$(PATCH).$(BUILD)-$(CHOST).tar.gz
endif

md5: src
	find src -type f -exec md5sum "{}" + > src.md5

asandwich:
	@test `whoami` = 'root' && echo OK || echo make it yourself!

.PHONY: all K $(SOURCE) hlep hepl help doc test src assets assets.o dist download clean cleandb list screen start stop restart startall stopall restartall packages system_install uninstall install docker reinstall diff latest changelog test-c release md5 asandwich
