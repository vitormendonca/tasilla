enum LearningSkill {
  listening,
  reading,
  vocabularyUseOfEnglish,
  writing,
  speaking,
  mixed,
}

enum ActivityKind {
  coreActivity,
  reinforcementActivity,
  review,
  checkpoint,
  portfolioTask,
  finalExam,
}

enum ActivityStatus {
  pending,
  inProgress,
  completed,
  reviewNeeded,
  submitted,
  approved,
  rejected,
  locked,
}

extension LearningSkillLabel on LearningSkill {
  String get label {
    switch (this) {
      case LearningSkill.listening:
        return 'Listening';
      case LearningSkill.reading:
        return 'Reading';
      case LearningSkill.vocabularyUseOfEnglish:
        return 'Vocabulary / Use of English';
      case LearningSkill.writing:
        return 'Writing';
      case LearningSkill.speaking:
        return 'Speaking';
      case LearningSkill.mixed:
        return 'Mixed';
    }
  }

  String get storageKey {
    switch (this) {
      case LearningSkill.listening:
        return 'listening';
      case LearningSkill.reading:
        return 'reading';
      case LearningSkill.vocabularyUseOfEnglish:
        return 'vocabulary_use_of_english';
      case LearningSkill.writing:
        return 'writing';
      case LearningSkill.speaking:
        return 'speaking';
      case LearningSkill.mixed:
        return 'mixed';
    }
  }
}

extension ActivityKindLabel on ActivityKind {
  String get label {
    switch (this) {
      case ActivityKind.coreActivity:
        return 'Core Activity';
      case ActivityKind.reinforcementActivity:
        return 'Reinforcement';
      case ActivityKind.review:
        return 'Review';
      case ActivityKind.checkpoint:
        return 'Checkpoint';
      case ActivityKind.portfolioTask:
        return 'Portfolio Task';
      case ActivityKind.finalExam:
        return 'Final Exam';
    }
  }

  String get storageKey {
    switch (this) {
      case ActivityKind.coreActivity:
        return 'core_activity';
      case ActivityKind.reinforcementActivity:
        return 'reinforcement_activity';
      case ActivityKind.review:
        return 'review';
      case ActivityKind.checkpoint:
        return 'checkpoint';
      case ActivityKind.portfolioTask:
        return 'portfolio_task';
      case ActivityKind.finalExam:
        return 'final_exam';
    }
  }
}

extension ActivityStatusState on ActivityStatus {
  String get storageKey {
    switch (this) {
      case ActivityStatus.pending:
        return 'pending';
      case ActivityStatus.inProgress:
        return 'in_progress';
      case ActivityStatus.completed:
        return 'completed';
      case ActivityStatus.reviewNeeded:
        return 'review_needed';
      case ActivityStatus.submitted:
        return 'submitted';
      case ActivityStatus.approved:
        return 'approved';
      case ActivityStatus.rejected:
        return 'rejected';
      case ActivityStatus.locked:
        return 'locked';
    }
  }

  bool get countsAsCompleted {
    switch (this) {
      case ActivityStatus.completed:
      case ActivityStatus.submitted:
      case ActivityStatus.approved:
        return true;
      case ActivityStatus.pending:
      case ActivityStatus.inProgress:
      case ActivityStatus.reviewNeeded:
      case ActivityStatus.rejected:
      case ActivityStatus.locked:
        return false;
    }
  }
}
