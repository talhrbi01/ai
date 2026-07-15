# بناء مجاني من Windows

لا يمكن لـ Windows تشغيل `xcodebuild` محليًا. الحل المجاني العملي هو استخدام جهاز macOS مستضافًا في GitHub Actions، ثم توقيع الناتج على Windows.

## المسار الأساسي: Codemagic

هذا المستودع يحتوي على `codemagic.yaml` لبناء IPA غير موقّع على جهاز macOS مستضاف.

1. أنشئ حسابًا شخصيًا مجانيًا في [Codemagic](https://codemagic.io/).
2. اربط حساب GitHub واختر المستودع `talhrbi01/ai`.
3. اختر Workflow باسم `mashhad-ios-free` ثم شغّل البناء.
4. بعد نجاح البناء نزّل artifact باسم `Mashhad-unsigned.ipa`.
5. على Windows استخدم Sideloadly أو AltStore لإعادة توقيع الملف بحساب Apple مجاني، ثم ثبّته على iPhone.

الخطة الشخصية المجانية في Codemagic تمنح 500 دقيقة بناء macOS شهريًا، وهي كافية لهذا البناء التجريبي عادةً.

## المسار البديل: GitHub Actions

يمكن استخدام Workflow الموجود في `.github/workflows/free-ios-ipa.yml` بالطريقة التالية:

1. أنشئ مستودعًا عامًا في GitHub وارفع المشروع إليه.
2. تأكد أن الملف `.github/workflows/free-ios-ipa.yml` موجود في الفرع `main`.
3. افتح تبويب `Actions`، ثم Workflow باسم `Free iOS IPA Artifact`، واضغط `Run workflow`.
4. بعد نجاح التشغيل نزّل artifact باسم `Mashhad-unsigned-ipa`.
5. على Windows استخدم Sideloadly أو AltStore لإعادة توقيع الملف بحساب Apple مجاني، ثم ثبّته على iPhone.

## القيود المجانية

- الملف الناتج من GitHub غير موقّع؛ لا يُثبّت مباشرة على iPhone قبل إعادة توقيعه.
- حساب Apple المجاني يجعل التطبيق صالحًا عادةً لمدة 7 أيام، مع حد أقصى للتطبيقات الموقعة المجانية على الجهاز. يجب إعادة التوقيع دوريًا.
- Developer Mode مطلوب في iOS 16 أو أحدث.
- هذا المسار لا ينتج IPA صالحًا لـ TestFlight أو App Store. التوزيع الرسمي يحتاج عضوية Apple Developer وشهادة توزيع وملف provisioning.
- التطبيق يضم entitlement خاصًا بـ Sign in with Apple. قد يرفض التوقيع المجاني هذا entitlement؛ عندها يمكن تشغيل الشريحة المحلية بعد إزالة ميزة Apple Sign In من نسخة الاختبار فقط.

## لماذا هذا المسار؟

يوفر Codemagic خطة شخصية مجانية بوقت macOS محدود، بينما يوفر GitHub macOS runners للمستودعات العامة عند عدم وجود قفل فوترة على الحساب. كلا المسارين يستخدمان `xcodebuild archive` لبناء تطبيق الجهاز ثم يضعانه داخل `Payload` ويضغطانه كـ IPA. بعد ذلك تتم عملية التوقيع على Windows، فلا توجد أسرار توقيع أو شهادات داخل المستودع.
