import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 'auto' follows the phone language, otherwise 'ar' or 'en'.
final ValueNotifier<String> langPref = ValueNotifier<String>('auto');
String _sys = 'en';

void initLang(SharedPreferences p) {
  langPref.value = p.getString('lang') ?? 'auto';
  _sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
}

String get lang => langPref.value == 'auto' ? (_sys == 'ar' ? 'ar' : 'en') : langPref.value;
bool get isAr => lang == 'ar';

const _ar = <String, String>{
  'Home': 'الرئيسية', 'Explore': 'استكشف', 'Activity': 'النشاط', 'Coach': 'المدرب', 'More': 'المزيد',
  'Welcome': 'أهلا بك', 'Your name': 'اسمك', 'Gender': 'الجنس', 'Male': 'ذكر', 'Female': 'أنثى', 'Birth date': 'تاريخ الميلاد',
  'Height (cm)': 'الطول (سم)', 'Weight (kg)': 'الوزن (كجم)', 'Next': 'التالي', 'Back': 'رجوع', 'About you': 'عنك', 'Your photo': 'صورتك', 'Choose photo': 'اختر صورة', 'Change photo': 'غيّر الصورة', 'Remove photo': 'احذف الصورة', 'Optional.': 'اختياري.', 'Your body': 'جسمك', 'Finish': 'إنهاء',
  'Where do you train?': 'أين تتمرن؟', 'At home': 'في المنزل', 'At the gym': 'في النادي', 'Gym': 'النادي',
  'Language': 'اللغة', 'Auto': 'تلقائي', 'Choose your language': 'اختر لغتك',
  'Your data stays on this phone.': 'بياناتك تبقى على هذا الهاتف فقط.',
  'Hello': 'مرحبا', "Today's workout": 'تمرين اليوم', 'Start workout': 'ابدأ التمرين', 'Program progress': 'تقدم البرنامج',
  'Today': 'اليوم', 'Rest day': 'يوم راحة', 'Quick workouts': 'تمارين سريعة', 'Mode': 'النمط', 'exercises': 'تمارين', 'min': 'دقيقة',
  'Collections': 'المجموعات', 'Exercise library': 'مكتبة التمارين', 'Search exercises': 'ابحث عن تمرين', 'All': 'الكل',
  'Strength': 'قوة', 'HIIT': 'تمارين عالية الشدة', 'Mobility': 'مرونة', 'Yoga': 'يوغا', 'Running': 'جري',
  'Days active this month': 'أيام النشاط هذا الشهر', "Today's sessions": 'جلسات اليوم', 'Weekly adherence': 'الالتزام الأسبوعي',
  'Totals': 'الإجمالي', 'Sessions': 'جلسات', 'Minutes': 'دقائق', 'Sets': 'مجموعات', 'Reps': 'تكرارات', 'No sessions yet': 'لا توجد جلسات بعد',
  'Planned': 'مخطط', 'Done': 'تم', 'Schedule': 'الجدول', 'Add schedule': 'إضافة موعد', 'This week': 'هذا الأسبوع', 'Save': 'حفظ', 'Cancel': 'إلغاء',
  'Choose a workout': 'اختر تمرينا', 'Time': 'الوقت', 'Nothing scheduled': 'لا يوجد شيء مجدول', 'Delete': 'حذف',
  'Set': 'المجموعة', 'of': 'من', 'reps': 'تكرار', 'sec': 'ثانية', 'Complete set': 'أنهيت المجموعة', 'Rest': 'راحة', 'Skip rest': 'تخطي الراحة',
  'Start timer': 'ابدأ المؤقت', 'Workout complete': 'اكتمل التمرين', 'Great work!': 'عمل رائع!', 'Close': 'إغلاق', 'Quit workout?': 'إنهاء التمرين؟', 'Quit': 'إنهاء', 'Keep going': 'استمر',
  'Ask your coach': 'اسأل مدربك', 'Type a message': 'اكتب رسالة', 'Not medical advice. Check with a doctor before starting a new program.': 'ليست نصيحة طبية. استشر طبيبا قبل بدء برنامج جديد.',
  'The coach is not available right now. Try again later.': 'المدرب غير متاح الآن. حاول لاحقا.', 'Thinking...': 'جار التفكير...',
  'Coach hello': 'أهلا! أنا مدربك. اسألني عن التمارين أو الأكل أو الراحة.',
  'Profile': 'الملف الشخصي', 'Delete my data': 'حذف بياناتي', 'Delete all data?': 'حذف كل البيانات؟', 'This removes your profile, history and schedule from this phone.': 'سيحذف هذا ملفك وسجلك وجدولك من هذا الهاتف.',
  'About': 'عن التطبيق', 'No ads. No login. Works offline.': 'بلا إعلانات. بلا تسجيل. يعمل بلا إنترنت.', 'Version': 'الإصدار',
  'Equipment': 'المعدات', 'Target muscle': 'العضلة المستهدفة', 'Also works': 'تعمل أيضا', 'How to': 'طريقة الأداء',
  'Instructions are in English for now.': 'التعليمات بالإنجليزية حاليا.',
  'Full body': 'الجسم كاملا', 'Upper body': 'الجزء العلوي', 'Lower body': 'الجزء السفلي', 'Core and cardio': 'البطن والكارديو', 'HIIT blast': 'حرق سريع', 'Mobility flow': 'مرونة وإطالة', 'Yoga and flexibility': 'يوغا ومرونة', 'Easy run and cardio': 'جري وكارديو',
  'Mon': 'اثنين', 'Tue': 'ثلاثاء', 'Wed': 'أربعاء', 'Thu': 'خميس', 'Fri': 'جمعة', 'Sat': 'سبت', 'Sun': 'أحد',
  'waist': 'البطن', 'back': 'الظهر', 'chest': 'الصدر', 'upper arms': 'الذراعان', 'shoulders': 'الأكتاف', 'upper legs': 'الفخذان', 'lower legs': 'السمانة', 'lower arms': 'الساعدان', 'cardio': 'كارديو', 'neck': 'الرقبة',
  'body weight': 'وزن الجسم', 'dumbbell': 'دمبل', 'barbell': 'بار', 'cable': 'كيبل', 'leverage machine': 'جهاز', 'band': 'حبل مقاومة', 'resistance band': 'حبل مقاومة', 'smith machine': 'جهاز سميث', 'kettlebell': 'كيتل بيل', 'stability ball': 'كرة ثبات', 'ez barbell': 'بار EZ', 'assisted': 'بمساعدة', 'sled machine': 'جهاز سليد', 'medicine ball': 'كرة طبية', 'rope': 'حبل', 'roller': 'أسطوانة',
  'abs': 'البطن', 'pectorals': 'الصدر', 'lats': 'الظهر العريض', 'quads': 'الفخذ الأمامي', 'hamstrings': 'الفخذ الخلفي', 'glutes': 'الأرداف', 'biceps': 'البايسبس', 'triceps': 'الترايسبس', 'delts': 'الأكتاف', 'calves': 'السمانة', 'forearms': 'الساعدان', 'traps': 'الترابيس', 'spine': 'العمود الفقري', 'upper back': 'أعلى الظهر', 'abductors': 'المبعدات', 'adductors': 'المقربات', 'serratus anterior': 'المنشارية', 'cardiovascular system': 'القلب والدورة الدموية', 'levator scapulae': 'رافعة الكتف', 'lower back': 'أسفل الظهر', 'hip flexors': 'ثانيات الورك', 'core': 'الجذع', 'shoulders ': 'الأكتاف',
  'Today, no workout planned': 'لا يوجد تمرين مخطط اليوم', 'Add': 'إضافة', 'Add to schedule': 'أضف للجدول', 'Done today': 'تم اليوم', 'Not medical advice.': 'ليست نصيحة طبية.',
  'Program': 'البرنامج', 'Week': 'الأسبوع', 'Years': 'سنة', 'Tap a day': 'اختر يوما', 'Streak': 'التتابع',
};

String tr(String k) => isAr ? (_ar[k] ?? k) : k;
String tl(String k) => isAr ? (_ar[k.toLowerCase()] ?? k) : k; // labels from data (muscles, equipment)
