import 'package:get/get.dart';
import 'app_routes.dart';
import '../transitions/slide_fade_transition.dart';

import '../../modules/auth/login_page.dart';
import '../../modules/auth/register_page.dart';
import '../../modules/student/home/home_page.dart';
import '../../modules/student/home/home_controller.dart';
import '../../modules/student/courses/courses_page.dart';
import '../../modules/student/courses/course_detail_page.dart';
import '../../modules/student/courses/courses_controller.dart';
import '../../modules/student/lecture/lecture_view_page.dart';
import '../../modules/student/wallet/wallet_page.dart';
import '../../modules/student/wallet/wallet_controller.dart';
import '../../modules/student/wallet/topup_page.dart';
import '../../modules/student/wallet/topup_controller.dart';
import '../../modules/student/notifications/notifications_page.dart';
import '../../modules/student/notifications/notifications_controller.dart';
import '../../modules/teacher/dashboard/teacher_home_page.dart';
import '../../modules/teacher/dashboard/teacher_home_controller.dart';
import '../../modules/teacher/courses/teacher_courses_page.dart';
import '../../modules/teacher/courses/teacher_course_detail_page.dart';
import '../../modules/teacher/courses/teacher_courses_controller.dart';
import '../../modules/teacher/lectures/add_edit_lecture_page.dart';
import '../../modules/teacher/earnings/earnings_page.dart';
import '../../modules/teacher/earnings/earnings_controller.dart';

class AppPages {
  static final pages = _rawPages
      .map((page) => page.copy(
            customTransition: SlideFadeTransition(),
            transitionDuration: const Duration(milliseconds: 280),
          ))
      .toList();

  static final List<GetPage> _rawPages = [
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
    GetPage(name: AppRoutes.studentHome, page: () => const HomePage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => HomeController());
    })),
    GetPage(name: AppRoutes.courses, page: () => const CoursesPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => CoursesController());
    })),
    GetPage(name: AppRoutes.courseDetail, page: () => const CourseDetailPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => CoursesController());
    })),
    GetPage(name: AppRoutes.lectureView, page: () => const LectureViewPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => LectureController());
    })),
    GetPage(name: AppRoutes.wallet, page: () => const WalletPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => WalletController());
    })),
    GetPage(name: AppRoutes.topup, page: () => const TopupPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => TopupController());
    })),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => NotificationsController());
    })),
    GetPage(name: AppRoutes.teacherHome, page: () => const TeacherHomePage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => TeacherHomeController());
    })),
    GetPage(name: AppRoutes.teacherCourses, page: () => const TeacherCoursesPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => TeacherCoursesController());
    })),
    GetPage(name: AppRoutes.teacherCourseDetail, page: () => const TeacherCourseDetailPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => TeacherCoursesController());
    })),
    GetPage(name: AppRoutes.addLecture, page: () => const AddEditLecturePage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => TeacherCoursesController());
    })),
    GetPage(name: AppRoutes.earnings, page: () => const EarningsPage(), binding: BindingsBuilder(() {
      Get.lazyPut(() => EarningsController());
    })),
  ];
}
