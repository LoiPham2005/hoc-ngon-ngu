# ═════════════════════════════════════════════════════════════════
# 📁 Makefile — lingua Automation (Bash/Zsh — Mac/Linux)
# ═════════════════════════════════════════════════════════════════

.PHONY: help \
        get clean upgrade \
        gen watch l10n full-gen gen-flavor fix-xcconfig gen-assets gen-icons gen-splash \
        analyze format fix \
        test cov \
        run-dev run-stg run-prod \
        apk-dev apk-stg apk-prod aab-dev aab-stg aab-prod \
        ios-dev ios-stg ios-prod ipa-dev ipa-stg ipa-prod \
        rename-package rename-app rename-bundle-id \
        mediation

# ─── HELP ─────────────────────────────────────────────────────────
help:
	@echo "🚀 lingua — Makefile"
	@echo "═══════════════════════════════════════════════════════════"
	@echo "📦 DEPENDENCIES"
	@echo "  make get                        Install dependencies"
	@echo "  make clean                      Clean build files"
	@echo "  make upgrade                    Upgrade major versions"
	@echo ""
	@echo "⚡ CODE GENERATION"
	@echo "  make gen                        build_runner build"
	@echo "  make watch                      build_runner watch"
	@echo "  make l10n                       Generate localizations"
	@echo "  make l10n-sync                  ARB: xoá key thừa + liệt kê key chưa dịch"
	@echo "  make l10n-sync-translate        Như trên + dịch key thiếu (Google) + gen-l10n"
	@echo "  make full-gen                   Clean + get + l10n + gen"
	@echo "  make gen-flavor                 Run flutter_flavorizr"
	@echo "  make gen-icons                  Generate launcher icons"
	@echo "  make gen-splash                 Generate native splash"
	@echo ""
	@echo "🔧 QUALITY"
	@echo "  make analyze                    flutter analyze"
	@echo "  make format                     dart format ."
	@echo "  make fix                        dart fix --apply"
	@echo ""
	@echo "🧪 TESTING"
	@echo "  make test                       Run all tests"
	@echo "  make cov                        Test + coverage HTML"
	@echo ""
	@echo "🧑‍💻 RUN (per flavor)"
	@echo "  make run-dev | run-stg | run-prod"
	@echo ""
	@echo "📦 BUILD ANDROID"
	@echo "  make apk-dev | apk-stg | apk-prod"
	@echo "  make aab-dev | aab-stg | aab-prod"
	@echo ""
	@echo "🍎 BUILD iOS (chỉ chạy trên macOS)"
	@echo "  make ios-dev | ios-stg | ios-prod    .app chưa ký (CI/test)"
	@echo "  make ipa-dev | ipa-stg | ipa-prod    .ipa (TestFlight — cần Apple signing)"
	@echo ""
	@echo "🛠️  RENAME"
	@echo "  make rename-package name=new_pkg"
	@echo "  make rename-app     name=\"App Name\""
	@echo "  make rename-bundle-id name=com.x.y"
	@echo ""
	@echo "💰 ADS"
	@echo "  make mediation networks=\"applovin meta unity\"   Thêm adapter mediation (gma_mediation_<mạng>) + pod iOS"

# ─── DEPENDENCIES ─────────────────────────────────────────────────
get:
	fvm flutter pub get

clean:
	fvm flutter clean

upgrade:
	fvm flutter pub upgrade --major-versions

# ─── CODE GENERATION ──────────────────────────────────────────────
gen:
	fvm dart run build_runner build --delete-conflicting-outputs

watch:
	fvm dart run build_runner watch --delete-conflicting-outputs

l10n:
	fvm flutter gen-l10n

l10n-sync:
	fvm dart run tools/l10n_sync.dart

l10n-sync-translate:
	fvm dart run tools/l10n_sync.dart --translate && fvm flutter gen-l10n

full-gen:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm dart run build_runner build --delete-conflicting-outputs

# Lần đầu: chạy đủ flavorizr. Đã setup: chỉ chạy bước an toàn (tên app, icon) — chạy lại đủ
# sẽ nhân đôi build config Xcode. Đổi bundleId iOS: sửa tay trong Xcode.
gen-flavor:
	@if grep -q 'Debug-dev' ios/Runner.xcodeproj/project.pbxproj; then \
		fvm dart run flutter_flavorizr -f -p android:flavorizrGradle,android:icons,ios:xcconfig,ios:icons && \
		$(MAKE) --no-print-directory fix-xcconfig; \
	else fvm dart run flutter_flavorizr; fi

# flavorizr sinh xcconfig include Pods chung → trỏ lại đúng biến thể (vd Pods-Runner.debug-dev).
fix-xcconfig:
	@for flavor in dev stg prod; do for mode in Debug Profile Release; do \
		lower=$$(echo $$mode | tr A-Z a-z); \
		sed -i '' -E "s|Pods-Runner\.[a-z-]+\.xcconfig|Pods-Runner.$$lower-$$flavor.xcconfig|" ios/Flutter/$$flavor$$mode.xcconfig; \
	done; done

gen-assets:
	fvm dart run build_runner build --delete-conflicting-outputs

gen-icons:
	fvm dart run flutter_flavorizr -f -p android:icons,ios:icons

gen-splash:
	fvm dart run flutter_native_splash:create

# ─── QUALITY ──────────────────────────────────────────────────────
analyze:
	fvm flutter analyze

format:
	fvm dart format .

fix:
	fvm dart fix --apply

# ─── TESTING ──────────────────────────────────────────────────────
test:
	fvm flutter test

cov:
	fvm flutter test --coverage
	@which genhtml > /dev/null && genhtml coverage/lcov.info -o coverage/html || echo "⚠️  Install lcov: brew install lcov"

# ─── RUN ──────────────────────────────────────────────────────────
run-dev:
	fvm flutter run --flavor dev

run-stg:
	fvm flutter run --flavor stg

run-prod:
	fvm flutter run --flavor prod

# ─── BUILD ────────────────────────────────────────────────────────
apk-dev:
	fvm flutter build apk --flavor dev --release

apk-stg:
	fvm flutter build apk --flavor stg --release

apk-prod:
	fvm flutter build apk --flavor prod --release

aab-dev:
	fvm flutter build appbundle --flavor dev --release

aab-stg:
	fvm flutter build appbundle --flavor stg --release

aab-prod:
	fvm flutter build appbundle --flavor prod --release

# ─── BUILD iOS (chỉ macOS) ────────────────────────────────────────
# ios-*  : .app CHƯA ký (--no-codesign) — hợp CI/test, không cần Apple account.
# ipa-*  : .ipa để lên TestFlight/App Store — CẦN cấu hình ký (Apple Developer +
#          Signing & Capabilities trong Xcode). Chưa ký sẽ báo lỗi codesign.
ios-dev:
	fvm flutter build ios --flavor dev --release --no-codesign

ios-stg:
	fvm flutter build ios --flavor stg --release --no-codesign

ios-prod:
	fvm flutter build ios --flavor prod --release --no-codesign

ipa-dev:
	fvm flutter build ipa --flavor dev --release

ipa-stg:
	fvm flutter build ipa --flavor stg --release

ipa-prod:
	fvm flutter build ipa --flavor prod --release

# ─── RENAME ───────────────────────────────────────────────────────
rename-package:
	@test -n "$(name)" || (echo "❌ Usage: make rename-package name=new_pkg" && exit 1)
	@OLD=$$(grep -m1 '^name: ' pubspec.yaml | awk '{print $$2}'); \
	echo "🔄 Renaming package $$OLD → $(name)"; \
	sed -i '' "s/^name: $$OLD/name: $(name)/" pubspec.yaml; \
	find lib test -name '*.dart' -exec sed -i '' "s|package:$$OLD|package:$(name)|g" {} +; \
	fvm flutter clean && fvm flutter pub get

rename-app:
	@test -n "$(name)" || (echo "❌ Usage: make rename-app name=\"App Name\"" && exit 1)
	fvm flutter pub run rename setAppName --value "$(name)"

rename-bundle-id:
	@test -n "$(name)" || (echo "❌ Usage: make rename-bundle-id name=com.x.y" && exit 1)
	fvm dart run rename setBundleId --targets android,ios --value "$(name)"

# ─── ADS MEDIATION ────────────────────────────────────────────────
# Thêm adapter mediation chính thức của Google rồi cài pod iOS. Code ads KHÔNG cần sửa;
# phần còn lại (AdMob, SKAdNetwork, Data safety…) xem skill modules → Mediation.
# Mạng có sẵn: applovin meta unity mintegral pangle ironsource liftoffmonetize inmobi dtexchange chartboost moloco
mediation:
	@test -n "$(networks)" || (echo "❌ Usage: make mediation networks=\"applovin meta unity\"" && exit 1)
	@for n in $(networks); do fvm flutter pub add gma_mediation_$$n || exit 1; done
	cd ios && pod install --repo-update
