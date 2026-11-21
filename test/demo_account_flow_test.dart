import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/services/connection_service.dart';

void main() {
  test('demo accounts can publish, apply, accept, and message', () async {
    addTearDown(ConnectionService.endDemoSession);
    const title = 'Demo account interaction test job';

    ConnectionService.beginDemoSession('Employer');
    await ConnectionService.publishPost(
      type: 'job',
      title: title,
      category: 'Electrical',
      description: 'A demo job shared with the worker account.',
    );
    final employerJob = (await ConnectionService.watchMyPosts(
      type: 'job',
    ).first).singleWhere((post) => post.title == title);

    ConnectionService.beginDemoSession('Tradesperson');
    final visibleJobs = await ConnectionService.watchPosts(type: 'job').first;
    final visibleJob = visibleJobs.singleWhere(
      (post) => post.id == employerJob.id,
    );
    await ConnectionService.requestPost(visibleJob);
    final sentRequest = (await ConnectionService.watchRequests(
      incoming: false,
    ).first).singleWhere((request) => request.postId == employerJob.id);

    ConnectionService.beginDemoSession('Employer');
    final application = (await ConnectionService.watchRequests(
      incoming: true,
    ).first).singleWhere((request) => request.id == sentRequest.id);
    await ConnectionService.respondToRequest(application, accept: true);

    ConnectionService.beginDemoSession('Tradesperson');
    final acceptedRequest = (await ConnectionService.watchRequests(
      incoming: false,
    ).first).singleWhere((request) => request.id == sentRequest.id);
    await ConnectionService.sendMessage(acceptedRequest, 'I am available.');

    ConnectionService.beginDemoSession('Employer');
    final messages = await ConnectionService.watchMessages(
      sentRequest.id,
    ).first;
    expect(messages.single.text, 'I am available.');
    expect(messages.single.senderName, 'Md. Asif Hasan');
  });

  test('demo trainer and client can publish and enroll in a course', () async {
    addTearDown(ConnectionService.endDemoSession);
    const title = 'Demo account interaction test course';

    ConnectionService.beginDemoSession('Trainer');
    await ConnectionService.publishPost(
      type: 'course',
      title: title,
      category: 'Electrical',
      description: 'A practical demo course.',
      priceBdt: 1800,
    );
    final trainerCourse = (await ConnectionService.watchMyPosts(
      type: 'course',
    ).first).singleWhere((post) => post.title == title);

    ConnectionService.beginDemoSession('User');
    final visibleCourse = (await ConnectionService.watchPosts(
      type: 'course',
    ).first).singleWhere((post) => post.id == trainerCourse.id);
    await ConnectionService.requestPost(
      visibleCourse,
      paymentMethod: 'cash',
      paymentStatus: 'awaiting_cash',
    );
    final sentRequest = (await ConnectionService.watchRequests(
      incoming: false,
    ).first).singleWhere((request) => request.postId == trainerCourse.id);

    ConnectionService.beginDemoSession('Trainer');
    var enrollment = (await ConnectionService.watchRequests(
      incoming: true,
    ).first).singleWhere((request) => request.id == sentRequest.id);
    await ConnectionService.respondToRequest(enrollment, accept: true);
    enrollment = (await ConnectionService.watchRequests(
      incoming: true,
    ).first).singleWhere((request) => request.id == sentRequest.id);
    await ConnectionService.confirmOfflinePayment(enrollment);

    ConnectionService.beginDemoSession('User');
    final updatedEnrollment = (await ConnectionService.watchRequests(
      incoming: false,
    ).first).singleWhere((request) => request.id == sentRequest.id);
    expect(updatedEnrollment.status, 'accepted');
    expect(updatedEnrollment.paymentStatus, 'confirmed_offline');
  });
}
