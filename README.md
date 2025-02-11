<div dir="rtl">

# وجیتا


[![build-image](https://github.com/yasershahi/vegeta/actions/workflows/build.yml/badge.svg)](https://github.com/yasershahi/vegeta/actions/workflows/build.yml)

 یک تصویر فدورا سیلوربلو که RPM Fusion را با کدک‌های رسانه‌ای اضافه می‌کند و [هومبرو][9] را یکپارچه می‌کند.

<picture>
  <source media="(prefers-color-scheme: light)" srcset=".github/screenshot-light.png">
  <source media="(prefers-color-scheme: dark)"  srcset=".github/screenshot-dark.png">
  <img title="تصویر صفحه" alt="تصویر صفحه" src=".github/screenshot-light.png">
</picture>

استفاده
-----

1. به یک تصویر بدون امضا تغییر پایه دهید تا کلیدهای امضای مناسب را دریافت کنید:
</div>

       rpm-ostree rebase -r ostree-unverified-registry:ghcr.io/yasershahi/vegeta:stable

<div dir="rtl">
2. به یک تصویر امضا شده تغییر پایه دهید تا نصب را کامل کنید:
</div>

       rpm-ostree rebase -r ostree-image-signed:docker://ghcr.io/yasershahi/vegeta:stable

<div dir="rtl">
به‌طور جایگزین، یک [فایل ISO برای نصب آفلاین][8] می‌تواند با
دستور زیر تولید شود:
</div>

    sudo podman run --rm --privileged \
        --volume .:/build-container-installer/build \
        --security-opt label=disable --pull=newer \
        ghcr.io/jasonn3/build-container-installer:latest \
        IMAGE_REPO="ghcr.io/yasershahi" \
        IMAGE_NAME="vegeta" \
        IMAGE_TAG="latest" \
        VARIANT="Silverblue"

<div dir="rtl">

ویژگی‌ها
--------

- با یک تصویر سفارشی فدورا سیلوربلو شروع کنید.
- [هومبرو][9] را بر روی `x86_64` نصب کنید.
- مخازن RPM Fusion و چندین بسته چندرسانه‌ای را اضافه کنید.

برای فعال‌سازی **هومبرو** فقط دستور زیر را اجرا کنید:
</div>

    sudo systemctl enable --now var-home-linuxbrew.mount

<div dir="rtl">

تأیید
------------

این تصاویر با [Cosign][4] سیگ‌استور امضا شده‌اند. شما می‌توانید
امضا را با دانلود کلید `cosign.pub` از این مخزن و اجرای
دستور زیر تأیید کنید:
</div>

    cosign verify --key cosign.pub ghcr.io/yasershahi/vegeta
<div dir="rtl">

منابع
----------

- [ساخت تصویر سفارشی فدورا سیلوربلو][5]
- [راهنما/OSTree - RPM Fusion][6]
- [Cosign - مستندات سیگ‌استور][4]
- [ساخت خودتان - یونیورسال بلو][7]
- [ویژگی: هومبرو بر روی تصویر توسط m2Giles · درخواست کشش #1128 · ublue-os/bazzite ·
  گیت‌هاب][10]
- [تعارض تنظیم مسیر هومبرو با باینری‌های میزبان · مسئله #687 ·
  ublue-os/bluefin · گیت‌هاب][11]
- [نصب مدیر بسته نیکس (کاربر واحد) بر روی فدورا سیلوربلو][13]
- [نیکس بر روی فدورا][14]


[1]:  https://github.com/aguslr/bluefusion
[2]:  https://github.com/containers/toolbox
[3]:  https://github.com/89luca89/distrobox
[4]:  https://docs.sigstore.dev/cosign/overview/
[5]:  https://www.ypsidanger.com/building-your-own-fedora-silverblue-image/
[6]:  https://rpmfusion.org/Howto/OSTree
[7]:  https://ublue.it/making-your-own/
[8]:  https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso
[9]:  https://brew.sh/
[10]: https://github.com/ublue-os/bazzite/pull/1128/commits/2dbf297
[11]: https://github.com/ublue-os/bluefin/issues/687
[12]: https://nixos.org/download/
[13]: https://gist.github.com/queeup/1666bc0a5558464817494037d612f094
[14]: https://gist.github.com/matthewpi/08c3d652e7879e4c4c30bead7021ff73

</div>
