
#set page(
  paper: "a4",
  margin: (x: 1.8cm, y: 1.5cm),
  numbering: "- ۱ -",
)

#set par(justify: true)

#set text(
  font: "IRNazanin",
  size: 14pt,
  lang: "fa",
  dir: rtl,
)

#align(
  center,
  text(16pt, orange)[
    = به نام خدا
  ],
)

\

#text(14pt)[
  تمرین سری ۱ مدیریت امنیت اطلاعات

  امیرحسین قدیری #h(5%) ۴۰۴۲۰۵۰۳۱
]

\

#text(orange)[
  = بخش ۲.۱
]

\

به منظور راه‌اندازی
swtpm
از دستورات زیر استفاده می‌شود.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  rm -rf /tmp/swtpm
  mkdir -p /tmp/swtpm

  swtpm socket --tpm2 --server type=tcp,port=2321 --ctrl type=tcp,port=2322 --tpmstate dir=/tmp/swtpm --flags startup-clear
  ```
]))

با استفاده از این دستورات، یک سرور
TPM 2.0
بر روی پورت
2321
و یک سرور کنترلی بر روی پورت
2322
راه‌اندازی می‌شود.
در مسیر
#text(dir: ltr, "/tmp/swtpm")
نیز وضعیت
TPM
ذخیره شده است.

#image("assets/2.1.1.png")

با تنظیم مقدار متغیر
TPM2TOOLS_TCTI
می‌توان در یک ترمینال دیگر از دستور
tpm2_getrandom
استفاده نمود.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  export TPM2TOOLS_TCTI="swtpm:host=localhost,port=2321"
  tpm2_getrandom 4 -o out.bin
  hexdump out.bin
  ```
]))

#image("assets/2.1.2.png")

#pagebreak()

#text(orange)[
  = بخش ۲.۲
]

\

ابتدا با استفاده از دستور زیر یک
Endorsement Key
ساخته شده است.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_createek -c ek-1.ctx -u ek-1.pub
  ```
]))

در ادامه با حذف دایرکتوری
#text(dir: ltr, "/tmp/swtpm")
و راه‌اندازی دوباره
swtpm،
وضعیت
TPM
دوباره راه‌اندازی شده و یک
Endorsement Key
دیگر می‌سازیم.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_createek -c ek-2.ctx -u ek-2.pub
  ```
]))

با مقایسه دو کلید ساخته شده، مشاهده می‌شود که این دو متفاوت می‌باشند.
مقایسه دو کلید ساخته شده به صورت زیر است.

#image("assets/2.2.1.png")

در ادامه به منظور ساخت یک
Attestation Identity Key
از دستور زیر استفاده شده است.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_createek -c ek.ctx
  tpm2_createak -C ek.ctx -c aik.ctx -G rsa -g sha256 -s rsassa -u aik.pub -n aik.name
  ```
]))

#image("assets/2.2.2.png")

سپس برای
persist
کردن این کلید از دستورات زیر استفاده شده است.
در اینجا، مقدار
0x81010002
یک
handle
برای دسترسی به این کلید می‌باشد.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_flushcontext -t
  tpm2_evictcontrol -C o -c aik.ctx 0x81010002
  ```
]))

#image("assets/2.2.3.png")

به منظور مشاهده کلیدهای
persist
شده و مشاهده کلید مورد نظر، از دستورات زیر استفاده شده است.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_getcap handles-persistent
  tpm2_readpublic -c 0x81010002
  ```
]))

#image("assets/2.2.4.png")

#pagebreak()

#text(orange)[
  = بخش ۲.۳
]

\

برای این بخش ابتدا سه فایل زیر ساخته شده‌اند که به ترتیب مقادیر
FLAG{S4LAB}
و
STATE_HEALTHY
و
STATE_MALICIOUS
در آن‌ها ذخیره شده‌اند.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  echo -n "FLAG{S4LAB}" > secret.txt
  echo -n "STATE_HEALTHY" > healthy.txt
  echo -n "STATE_MALICIOUS" > malicious.txt
  ```
]))

در ادامه وضعیت
PCR16
با هش
sha256
مقدار
STATE_HEALTHY
گسترش داده شده و یک
policy
بر اساس مقدار جدید آن ساخته شده است.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_pcrextend 16:sha256=$(sha256sum healthy.txt | cut -d' ' -f1)
  tpm2_createpolicy --policy-pcr -l sha256:16 -L policy.dat
  ```
]))

#image("assets/2.3.1.png")

حالا مقدار مخفی ذخیره شده در فایل با استفاده از دستورات زیر
seal
شده و یک
context
برای دسترسی به آن ساخته می‌شود.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_createprimary -C o -c primary.ctx
  tpm2_create -C primary.ctx -L policy.dat -i secret.txt -u seal.pub -r seal.priv
  tpm2_flushcontext -t
  tpm2_load -C primary.ctx -u seal.pub -r seal.priv -c seal.ctx
  ```
]))

#image("assets/2.3.2.png")

#image("assets/2.3.3.png")

\

== حالت اول
#v(1.5%)

در این حالت، بررسی می‌شود که بتوان مقدار مخفی را با موفقیت
unseal
کرده و آن را مشاهده نمود.
این عمل با استفاده از دستورات زیر انجام شده است.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_flushcontext -t

  tpm2_startauthsession --policy-session -S session.ctx
  tpm2_policypcr -S session.ctx -l sha256:16
  tpm2_unseal -c seal.ctx -p "session:session.ctx"
  ```
]))

#image("assets/2.3.4.png")

\

== حالت دوم
#v(1.5%)

در این حالت، مشاهده می‌شود که با راه‌اندازی مجدد وضعیت
PCR16
و گسترش آن با استفاده هش
sha256
مقدار
STATE_MALICIOUS،
دیگر امکان
unseal
کردن مقدار مخفی وجود نداشته و
policy
نقض می‌شود.
این عمل با استفاده از دستورات زیر انجام شده است.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_flushcontext -t
  tpm2_pcrreset 16
  tpm2_pcrextend 16:sha256=$(sha256sum malicious.txt | cut -d' ' -f1)

  tpm2_startauthsession --policy-session -S session.ctx
  tpm2_policypcr -S session.ctx -l sha256:16
  tpm2_unseal -c seal.ctx -p "session:session.ctx"
  ```
]))

#image("assets/2.3.5.png")

\

== حالت سوم
#v(1.5%)

در این حالت، مشاهده می‌شود که با راه‌اندازی مجدد وضعیت
PCR16
و گسترش آن با استفاده هش
sha256
مقدار
STATE_HEALTHY
می‌توان مقدار مخفی را با موفقیت
unseal
کرده و آن را مشاهده نمود.
این عمل با استفاده از دستورات زیر انجام شده است.

#align(left, text(dir: ltr, size: 12pt, [
  ```bash
  tpm2_flushcontext -t
  tpm2_pcrreset 16
  tpm2_pcrextend 16:sha256=$(sha256sum healthy.txt | cut -d' ' -f1)

  tpm2_startauthsession --policy-session -S session.ctx
  tpm2_policypcr -S session.ctx -l sha256:16
  tpm2_unseal -c seal.ctx -p "session:session.ctx"
  ```
]))

#image("assets/2.3.6.png")

#pagebreak()

#text(orange)[
  = بخش ۳
]

\

== سوال ۱
#v(1.5%)

- Platform Hierarchy:
  این سلسه مراتب تخت کنترل سازنده پلتفرم یا
  firmware
  قرار دارد.
  هدف این سلسه مراتب، مدیریات تنظیمات سطح پایین
  TPM،
  ایجاد کلیدهایی برای استفاده داخلی سیستم و مدیریت برخی قابلیت‌ها در هنگام بوت می‌باشد.

- Storage Hierarchy:
  مهم‌ترین سلسه مراتب برای کاربران و برنامه‌ها بوده و برای حفاظت و ذخیره‌سازی کلیدها از آن استفاده می‌شود.
  هدف این سلسله مراتب ایجاد کلید‌های فضای ذخیره‌سازی و رمزنگاری و محافظت از کلیدهای دیگر می‌باشد.

- Endorsement Hierarchy:
  از این سلسله مراتب برای اثبات هویت و اعتبار
  TPM
  استفاده می‌شود.
  هدف این سلسه مراتب نگهداری از
  Endorsement Key
  ها، پشتیبانی از
  Remote Attestation
  و اثبات معتبر بودن
  TPM
  می‌باشد.

- Null Hierarchy:
  این سلسه مراتب موقت و بدون ذخیره‌سازی دائمی می‌باشد.
  هدف این سلسله مراتب ایجاد کلیدها و اشیای موقت و جلوگیری از باقی‌ماندن داده‌های حساس پس از راه‌اندازی مجدد می‌باشد.

در
TPM 1.2
تقریبا همه عملکردها به یک سلسله مراتب ذخیره‌سازی واحد وابسته بودند. این موضوع مشکلاتی مانند تمرکز بیش از حد اعتماد روی یک بخش دشواری تفکیک وظایف مدیریتی و محدودیت کنترل دسترسی را ایجاد می‌کرد.

اما در
TPM 2.0
هر سلسله مراتب مستقل بوده و هر کدام دارای
seed
و
authorization
جداگانه می‌باشند.
همچنین امکان جداسازی نقش‌ها فراهم شده و مدیریت کلید‌ها انعطاف‌پذیرتر و ایمن‌تر می باشد.
به طور مثال اگر کلید‌های
Storage Hierarchy
به خطر بیافتند، کلیدهای
Endorsement Hierarchy
همچنان امن باقی خواهند ماند.

#pagebreak()

== سوال ۲
#v(1.5%)

PCR
ها در
TPM
نقش بسیار مهمی در تضمین یکپارچگی فرآیند بوت و همچنین پیاده‌سازی
Remote Attestation
دارند.
این رجیسترها مقادیر هش مربوط به اجزای مختلف سیستم را در طول بوت ذخیره می‌کنند تا
TPM
بتواند تشخیص دهد آیا سیستم در وضعیت قابل اعتماد اجرا شده است یا خیر.

در فرآیند بوت، هر مؤلفه قبل از اجرا اندازه‌گیری شده و هش می‌شود.
برای مثال هش
BIOS
یا
UEFI
ابتدا محاسبه شده و نتیجه در یکی از
PCR
ها ثبت می‌گردد.
سپس
bootloader
و
kernel
و در ادامه بقیه اجزا هش گرفته می‌شوند.
به این ترتیب یک زنجیره اعتماد ایجاد می‌شود که در آن هر مرحله وضعیت مرحله قبلی را نیز در خود منعکس می‌کند.
اگر حتی بخش کوچکی از یکی از اجزا تغییر کند، مقدار هش متفاوت خواهد شد و در نتیجه مقدار
PCR
نیز تغییر می‌کند.
بنابراین
TPM
می‌تواند تغییرات غیرمجاز مانند وجود
bootkit
یا
rootkit
را تشخیص دهد.

ویژگی مهم
PCR
ها این است که مقدار آن‌ها مستقیما
overwrite
نمی‌شود، بلکه فقط از طریق عملیاتی به نام
extend
تغییر می‌کنند. در عملیات
extend،
مقدار جدید
PCR
از ترکیب مقدار قبلی
PCR
و ورودی جدید به دست می‌آید.

این طراحی باعث می‌شود
PCR
ها در برابر دستکاری مقاوم باشند زیرا مهاجم نمی‌تواند مقدار دلخواهی را مستقیم داخل
PCR
قرار دهد.
همچنین هر مقدار جدید به مقدار قبلی وابسته می‌باشد، بنابراین اگر مهاجم بخواهد یکی از مراحل بوت را تغییر دهد، کل زنجیره هش‌ها تغییر خواهد کرد.
در نتیجه بازگرداندن یک مقدار قدیمی یا جعل وضعیت سالم سیستم تقریبا غیرممکن می‌شود.
این خاصیت را
Tamper Resistance
می‌نامند.

PCR
ها همچنین پایه اصلی
Remote Attestation
هستند.
در
Remote Attestation،
سیستم مقادیر
PCR
را از
TPM
دریافت می‌کند و
TPM
این مقادیر را با یک
Attestation Key
امضا می‌کند.
سپس این اطلاعات به یک سیستم راه‌دور ارسال می‌شود.
سیستم راه‌دور امضا را بررسی کرده و مقادیر
PCR
را با مقادیر مورد انتظار مقایسه می‌کند.
اگر مقادیر با وضعیت سالم و مورد اعتماد سیستم مطابقت داشته باشند، سیستم معتبر شناخته می‌شود.
اما اگر
bootloader،
kernel
یا
firmware
دستکاری شده باشند، مقادیر
PCR
متفاوت خواهد بود و فرآیند
Attestation
شکست می‌خورد.

قابلیت
sealing
و
unsealing
نیز به
PCR
ها وابسته می‌باشند.
در
TPM
می‌توان داده یا کلیدی را به وضعیت خاصی از سیستم وابسته نمود.
به این صورت هنگام
seal
کردن،
TPM
مقادیر فعلی
PCR
را همراه داده ذخیره می‌کند.
سپس هنگام
unseal
کردن،
TPM
ابتدا
PCR
های فعلی را بررسی می‌کند.
اگر این مقادیر دقیق با مقادیر ذخیره‌شده مطابقت داشته باشند،
TPM
داده یا کلید را آزاد می‌کند.
اما اگر وضعیت بوت تغییر کرده باشد و مقادیر
PCR
متفاوت باشند، عملیات
unseal
شکست می‌خورد.

#pagebreak()

== سوال ۳
#v(1.5%)

- Password Authorization:
  در این روش دسترسی به یک شی یا کلید فقط با دانستن یک مقدار مخفی مانند password
  یا
  authorization value
  امکان‌پذیر است.
  این ساده‌ترین روش احراز هویت در
  TPM 2.0
  محسوب می‌شود و مشابه استفاده از رمز عبور معمولی است.

- HMAC Authorization:
  در این مکانیزم از
  session
  و توابع رمزنگاری برای اثبات مالکیت
  authorization value
  استفاده می‌شود، بدون اینکه خود رمز مستقیما ارسال شود. این روش در برابر حملات شنود و
  replay attack
  امنیت بیشتری دارد.

- Extended Authorization Policy:
  این مهم‌ترین و قدرتمندترین مکانیزم
  TPM 2.0
  محسوب می‌شود.
  در این روش، دسترسی فقط به دانستن یک
  password
  وابسته نیست، بلکه
  TPM
  مجموعه‌ای از شرایط و
  policy
  ها را بررسی می‌کند.
  این
  policy
  ها می‌توانند شامل مقدار
  PCR
  ها،
  وضعیت
  Secure Boot،
  زمان،
  دستورات مجاز،
  یا حتی ترکیبی از چند شرط امنیتی باشند.

مزیت اصلی
Extended Authorization Policy
نسبت به
password
ساده این است که دسترسی را به یک وضعیت قابل اعتماد سیستم وابسته می‌کند.
در روش
password-based،
اگر مهاجم رمز را بداند، می‌تواند بدون توجه به وضعیت سیستم به داده دسترسی پیدا کند.
اما در
Extended Authorization Policy
حتی اگر مهاجم به فایل‌ها یا
object
دسترسی داشته باشد، تا زمانی که شرایط
policy
برقرار نباشد
TPM
اجازه استفاده از آن را نمی‌دهد.

این موضوع مستقیما در تمرین
sealing
و
unsealing
روی
PCR16
که در بخش عملی انجام شد دیده می‌شود.
در این تمرین ابتدا یک
policy
بر اساس مقدار
PCR16
ساخته شد؛ یعنی
TPM
فقط زمانی اجازه
unseal
کردن داده را می‌داد که
PCR16
شامل مقدار
STATE_HEALTHY
باشد.

در حالت اول، زمانی که
PCR16
مقدار صحیح
را داشت، عملیات
unseal
موفق بود و
TPM
رشته مخفی را برگرداند.
دلیل موفقیت این بود که مقدار فعلی
PCR
دقیقا با
policy
تعریف‌شده مطابقت داشت، بنابراین
TPM
سیستم را در وضعیت
trusted
تشخیص داد.

در حالت دوم، زمانی که
PCR16
به مقدار
STATE_MALICIOUS
تغییر داده شد، عملیات
unseal
شکست خورد و
TPM
خطای برگرداند.
علت این اتفاق این بود که
policy
تعریف‌شده فقط اجازه دسترسی در صورت وجود مقدار
STATE_HEALTHY
را می‌داد.

در حالت سوم، وقتی
PCR16
دوباره به مقدار اولیه
STATE_HEALTHY
بازگردانده شد، عملیات
unseal
دوباره موفق شد.
این نشان می‌دهد که
TPM
داده را نه بر اساس
password
بلکه بر اساس وضعیت اندازه‌گیری‌شده و قابل اعتماد سیستم آزاد می‌کند.
