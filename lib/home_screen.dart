import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'storage.dart';
import 'theme.dart';
import 'player.dart';
import 'inventory_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserStats? _s;
  String _playerAnim = 'Run'; // Refined in initState based on time
  int _playerAnimId = 0;
  String? _profileImagePath;
  ValueListenable<Box>? _dailyQuestsListenable;
  int _activeWeekIndex = 0;
  late final PageController _weeklyPageController;
  String? _bubbleMessage;
  Timer? _bubbleTimer;
  List<WeekendQuestion> _currentWeekendQuestions = [];
  bool _isDialogueOpen = false;
  int? _selectedQuestionIndex;
  List<int> _unusedJokeIndices = [];

  void _refreshWeekendQuestions() {
    final rand = Random();
    final List<WeekendQuestion> shuffled = List.from(_weekendPool)..shuffle(rand);
    setState(() {
      _currentWeekendQuestions = shuffled.take(3).toList();
    });
  }

  static const List<WeekendQuestion> _weekendPool = [
    WeekendQuestion("What is the Vault for?", "The Vault holds your rarest chests. Unlock them to get epic gear!"),
    WeekendQuestion("How do I level up fast?", "Complete daily quests and maintain your streak. XP adds up quickly!"),
    WeekendQuestion("What happens if I miss a day?", "Your streak might reset, but don't worry—just keep going tomorrow!"),
    WeekendQuestion("What is the Combat Engine?", "It's where you train with clone physics and test your skills!"),
    WeekendQuestion("How do I change my avatar?", "Go to the profile screen and tap on your avatar image to change it!"),
    WeekendQuestion("What are rank titles?", "As you gain total XP, your rank ascends from Bronze to legendary ranks!"),
    WeekendQuestion("Can I toggle dark mode?", "Yes! Tap the lightbulb or moon icon in the settings to toggle themes!"),
    WeekendQuestion("Where is my inventory?", "Tap the backpack icon at the top right of your home screen!"),
    WeekendQuestion("How do I unlock chests?", "You can open them instantly using your gems or gold in the Vault!"),
    WeekendQuestion("Are my stats saved?", "Yes, everything is safely saved locally using secure Hive storage!"),
    WeekendQuestion("What is your favorite workout?", "Coding and lifting! A robust brain and a strong body!"),
    WeekendQuestion("Do you sleep?", "Only when the system clock reads night. Stunned mode activated!"),
    WeekendQuestion("What is rest day?", "Today is rest day! Let's chat and prepare for the next week's grind!"),
    WeekendQuestion("How do I gain gold?", "Complete difficult quests and open gold chest rewards!"),
    WeekendQuestion("Can I customize quests?", "Yes, use the quests tab to add, edit, or delete any daily goals!"),
    WeekendQuestion("What is the best exercise?", "The squat! It builds character and absolute power!"),
    WeekendQuestion("Are you a real human?", "I am your digital fitness champion. But I feel the burn too!"),
    WeekendQuestion("Should I stretch?", "Always! Flexing your muscles keeps your compiler warnings low!"),
    WeekendQuestion("What's your power level?", "Currently over 9000! Let's get yours up there too!"),
    WeekendQuestion("How do I get gems?", "Gems are rewarded for milestone achievements and legendary quest clears!"),
    WeekendQuestion("Why is cardio important?", "It increases your stamina bar, letting you run from bugs faster!"),
    WeekendQuestion("What is your dream?", "To see you hit a perfect 30-day streak! We can do it!"),
    WeekendQuestion("Got any coder advice?", "Always comment your code and never skip leg day!"),
    WeekendQuestion("How do I reset my data?", "You can clear data in the settings screen if you want a fresh start."),
    WeekendQuestion("What is Rank System?", "A leveling metric based on XP needed to reach the next tier."),
    WeekendQuestion("Is there a streak limit?", "No limit! The sky is the limit. Chase that infinity streak!"),
    WeekendQuestion("Should I drink water?", "Yes! Hydration is the fuel of elite athletes and programmers!"),
    WeekendQuestion("What is Haptic feedback?", "Tactile vibrations when you click items, making the app feel alive!"),
    WeekendQuestion("Why the name Solo Gainz?", "Because you are the main character of your own solo leveling journey!"),
    WeekendQuestion("Can I see my history?", "Swipe left on the weekly progress row to see up to 3 weeks of history!"),
    WeekendQuestion("What are daily quests?", "Short habit-building tasks to complete every single day."),
    WeekendQuestion("How to beat the clone?", "Use quick punch and kick combos in the training screen!"),
    WeekendQuestion("What are chest tiers?", "Chests range from Common (wood) to legendary (glowing gold)!"),
    WeekendQuestion("Why is Sunday first?", "Because we start our week strong, planning ahead from the very first day!"),
    WeekendQuestion("How do I edit profile?", "Head over to the Profile screen to update your username and goals!"),
    WeekendQuestion("Who built this app?", "A legendary developer pair programming with an advanced AI champion!"),
    WeekendQuestion("What is the progress border?", "The circular green line showing how many daily quests you completed!"),
    WeekendQuestion("How do I complete a quest?", "Simply tap the checkbox next to the quest in the list!"),
    WeekendQuestion("Can I use this offline?", "Yes! Solo Gainz is 100% local and works completely offline!"),
    WeekendQuestion("What is the XP bar?", "The linear progress bar under your username showing level progress!"),
    WeekendQuestion("Why is rest important?", "Your muscles grow during rest, not during workouts. Sleep well!"),
    WeekendQuestion("Got any diet tips?", "Eat clean, minimize processed sugar, and get plenty of protein!"),
    WeekendQuestion("What is compile state?", "When my brain is translating your dedication into visual gainz!"),
    WeekendQuestion("How do I earn gear?", "Open rare chest drops in the inventory screen!"),
    WeekendQuestion("Why do you run?", "To maintain a high framerate and high stamina!"),
    WeekendQuestion("What is the daily reset?", "At midnight, your daily quests refresh for the new day!"),
    WeekendQuestion("Can I add custom habits?", "Absolutely! Add custom habits to track everything you care about."),
    WeekendQuestion("What is gem cost?", "Vault locks can be instantly bypassed using your accumulated gems."),
    WeekendQuestion("How to dodge knockback?", "Time your blocks or step back before the clone strikes!"),
    WeekendQuestion("What is active day?", "The highlighted blue-bordered square indicating today!"),
    WeekendQuestion("What is green square?", "A fully completed quest day. Wear it like a badge of honor!"),
    WeekendQuestion("What is red square?", "An incomplete past day. Don't worry, learn from it and move on!"),
    WeekendQuestion("Why do I feel sore?", "Soreness is just microscopic muscle fibers rebuilding stronger!"),
    WeekendQuestion("How to build discipline?", "Consistency beats intensity. Do a little bit every single day!"),
    WeekendQuestion("Is lifting dangerous?", "Only with bad form. Focus on execution before adding heavy weight!"),
    WeekendQuestion("What is dynamic icon?", "A feature allowing launcher icon customization in app settings!"),
    WeekendQuestion("How do I stay motivated?", "Motivation gets you started; habit keeps you going!"),
    WeekendQuestion("Is sugar bad?", "Excess sugar causes energy crashes. Choose complex carbs instead!"),
    WeekendQuestion("Can I train daily?", "Alternate muscle groups to give your body adequate time to recover!"),
    WeekendQuestion("What is Sleep Zs?", "When you log in late at night, I take a nap to restore energy!"),
    WeekendQuestion("Should I do cardio?", "Yes! Cardio keeps your heart healthy and burning fat efficiently!"),
    WeekendQuestion("How to fix bad form?", "Record yourself or train in front of a mirror to adjust posture!"),
    WeekendQuestion("What is a PR?", "Personal Record. Your highest weight or fastest time achieved!"),
    WeekendQuestion("What is the best prep?", "Pre-workout hydration and a solid warm-up dynamic stretch!"),
    WeekendQuestion("Are cheats allowed?", "Cheat meals are fine occasionally to boost metabolism and spirits!"),
    WeekendQuestion("How to grow biceps?", "Consistent bicep curls and chin-ups with controlled negatives!"),
    WeekendQuestion("Why do planks hurt?", "Because they recruit your entire core, testing true absolute endurance!"),
    WeekendQuestion("What is high fidelity?", "Our premium dark-themed design system featuring glass and neon!"),
    WeekendQuestion("Can I change my level?", "No, you must earn it through sweat and completed daily quests!"),
    WeekendQuestion("How do I unlock ranks?", "Rank up automatically as your total accumulated XP passes milestones!"),
    WeekendQuestion("How to gain focus?", "Put your phone in do-not-disturb mode before starting a workout!"),
    WeekendQuestion("What is your rank?", "I am an SS-Rank Fitness Companion. Ready to guide you to greatness!"),
    WeekendQuestion("What's a super-set?", "Performing two exercises back-to-back with no rest in between!"),
    WeekendQuestion("Is coffee good?", "Black coffee is an excellent, natural pre-workout booster!"),
    WeekendQuestion("How do I burn fat?", "Maintain a slight caloric deficit and combine resistance with cardio!"),
    WeekendQuestion("Why do I plateue?", "Your body adapted. Change your reps, weights, or exercises to shock it!"),
    WeekendQuestion("What is progressive overload?", "Gradually increasing weight, reps, or intensity over time to grow!"),
    WeekendQuestion("Can I do yoga?", "Yes! Flexibility prevents injury and speeds up muscle recovery!"),
    WeekendQuestion("Why is form first?", "Because injury stops all progress. Leave your ego at the door!"),
    WeekendQuestion("How to sleep better?", "Avoid screens 1 hour before bed and keep your room cool!"),
    WeekendQuestion("What is calorie count?", "Energy input. Track it if you want to dial in your body composition!"),
    WeekendQuestion("Got a fitness joke?", "Why did the programmer quit the gym? Because he couldn't resolve the weights!"),
    WeekendQuestion("Another joke?", "Why did the lifting coder use SQL? To execute a Squat Query Language!"),
    WeekendQuestion("Tell me a secret!", "If you complete a legendary chest, you might find secret easter eggs!"),
    WeekendQuestion("How's your code?", "Zero compiler warnings and 100% optimized for pure gainz!"),
    WeekendQuestion("What is gold chest?", "A premium chest containing rich resource payouts and high-tier gear!"),
    WeekendQuestion("Can I pause streak?", "Consistency doesn't take vacations, but listening to your body is key!"),
    WeekendQuestion("What is local storage?", "Your progress is secured directly on your device, private and fast!"),
    WeekendQuestion("Got a life quote?", "Success isn't owned, it's leased. And rent is due every single day!"),
    WeekendQuestion("What is combat simulator?", "Our dedicated training module featuring reactive combat physics!"),
    WeekendQuestion("What is double tap?", "A shorthand gesture to quickly activate primary actions!"),
    WeekendQuestion("How to build chest?", "Focus on bench press, incline press, and weighted dips!"),
    WeekendQuestion("Why are my legs sore?", "Squats recruit major muscle groups. Keep moving to flush lactic acid!"),
    WeekendQuestion("Can I change my join date?", "Your join date marks the official launch of your leveling journey!"),
    WeekendQuestion("What is neon cyan?", "Our flagship theme color, representing clean energy and focus!"),
    WeekendQuestion("Should I use straps?", "Use them for heavy pulls, but train raw grip to build forearm strength!"),
    WeekendQuestion("What is your level limit?", "My level is uncapped. I grow stronger alongside you!"),
    WeekendQuestion("How to stay young?", "Lift weights, eat colorful foods, stretch, and keep learning!"),
    WeekendQuestion("What is today's mission?", "To be slightly better than you were yesterday. Let's get it!"),
    WeekendQuestion("Are we champions?", "Yes! By choosing to show up today, you are already a champion!")
  ];

  String _typedBubbleMessage = "";
  Timer? _typewriterTimer;
  Timer? _idleChatterTimer;

  static const List<String> _idleMoves = [
    'Punch01',
    'Punch02',
    'Punch03',
    'Kick01',
    'Kick02',
    'Kick03',
  ];

  Timer? _touchIdleTimer;
  final List<String> _animationQueue = [];
  bool _isPlayingCombo = false;

  void _resetUserTouchTimer() {
    _touchIdleTimer?.cancel();
    if (_isPlayingCombo) {
      setState(() {
        _isPlayingCombo = false;
        _animationQueue.clear();
        final weekday = DateTime.now().weekday;
        final isWeekend = weekday == 6 || weekday == 7;
        _playerAnim = isWeekend ? 'Idle' : (_isNight ? 'Stunned' : 'Run');
        _playerAnimId++;
      });
    }
    _touchIdleTimer = Timer(const Duration(seconds: 20), () {
      _triggerRandomIdleCombo();
    });
  }

  void _triggerRandomIdleCombo() {
    if (!mounted || _isPlayingCombo) return;
    final rand = Random();
    final isCombo = rand.nextDouble() < 0.40;
    _animationQueue.clear();
    
    if (isCombo) {
      final comboLength = 2 + rand.nextInt(2);
      for (int i = 0; i < comboLength; i++) {
        _animationQueue.add(_idleMoves[rand.nextInt(_idleMoves.length)]);
      }
    } else {
      _animationQueue.add(_idleMoves[rand.nextInt(_idleMoves.length)]);
    }
    
    setState(() {
      _isPlayingCombo = true;
      _playNextQueueAnimation();
    });
  }

  void _playNextQueueAnimation() {
    if (_animationQueue.isEmpty) {
      setState(() {
        _isPlayingCombo = false;
        final weekday = DateTime.now().weekday;
        final isWeekend = weekday == 6 || weekday == 7;
        _playerAnim = isWeekend ? 'Idle' : (_isNight ? 'Stunned' : 'Run');
        _playerAnimId++;
      });
      _resetUserTouchTimer();
      return;
    }
    final nextAnim = _animationQueue.removeAt(0);
    setState(() {
      _playerAnim = nextAnim;
      _playerAnimId++;
    });
  }

  String _getRandomUniqueJoke() {
    if (_unusedJokeIndices.isEmpty) {
      _unusedJokeIndices = List<int>.generate(_jokes.length, (i) => i)..shuffle();
    }
    final index = _unusedJokeIndices.removeLast();
    return _jokes[index];
  }

  void _startIdleChatter() {
    _idleChatterTimer?.cancel();
    _idleChatterTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_bubbleMessage == null) {
        final rand = Random();
        final weekday = DateTime.now().weekday;
        final isWeekend = weekday == 6 || weekday == 7;
        final chatterChance = isWeekend ? 0.60 : 0.25;
        if (rand.nextDouble() < chatterChance) {
          final joke = _getRandomUniqueJoke();
          _say(joke, stayDuration: const Duration(seconds: 3));
        }
      }
    });
  }

  void _say(String message, {Duration stayDuration = const Duration(seconds: 1)}) {
    _bubbleTimer?.cancel();
    _typewriterTimer?.cancel();
    
    setState(() {
      _bubbleMessage = message;
      _typedBubbleMessage = "";
    });
    
    int charIndex = 0;
    const speed = Duration(milliseconds: 15); // Snappy retro typing speed!
    
    _typewriterTimer = Timer.periodic(speed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      charIndex++;
      if (charIndex <= message.length) {
        setState(() {
          _typedBubbleMessage = message.substring(0, charIndex);
        });
      } else {
        timer.cancel();
        _bubbleTimer = Timer(stayDuration, () {
          if (mounted) {
            setState(() {
              _bubbleMessage = null;
              _typedBubbleMessage = "";
            });
          }
        });
      }
    });
  }

  static const List<String> _jokes = [
    "Rest day? Never heard of her!",
    "I'm sore, but I'm back!",
    "No pain, no gainz!",
    "Debugging my abs!",
    "My calves are compiling!",
    "Java? I prefer coffee!",
    "Gym is my database!",
    "Push-ups completed!",
    "SQL: Squat Query Language!",
    "Byte-sized biceps!",
    "Cardio? Is that a Spanish word?",
    "Squat till you drop!",
    "CTRL+ALT+SWEAT!",
    "Running on coffee and dreams!",
    "Buffering my muscles...",
    "Error 404: Fat not found!",
    "My gym code is clean!",
    "Flexing my code!",
    "Sore today, SS-Rank tomorrow!",
    "My mouse is heavy!",
    "Sweating in binary!",
    "Eat. Sleep. Code. Lift.",
    "I don't sweat, I leak genius!",
    "Running... from my bugs!",
    "Biceps: loaded!",
    "Gym hair, don't care!",
    "Coded a new PR today!",
    "404: Rest day not found!",
    "One more rep!",
    "Stronger than my wifi!",
    "Glutes of steel!",
    "Is sweat a fluid design?",
    "Flexing my stack!",
    "My level is over 9000!",
    "Abs.exe is downloading...",
    "Plank time = Slow time!",
    "No lift, no gift!",
    "Lifting spirits and weights!",
    "Coder by day, beast by night!",
    "I lift, therefore I am.",
    "Running is my garbage collector!",
    "Squats? 100% compiled!",
    "My back is backed up!",
    "Muscle memory is RAM!",
    "Sweating out the fat!",
    "Too buff to debug!",
    "Gym time > Screen time!",
    "Cardio completed! Send help.",
    "Dumbbells and databases!",
    "Work hard, play hard!",
    "Crushing bugs and reps!",
    "My core is fully stable!",
    "Zero compiler warnings today!",
    "Beast mode: Activated!",
    "Sweat: the programmer's tears!",
    "Heavy metal therapy!",
    "My calves are modular!",
    "Gains are non-blocking!",
    "Lifting is a synchronized task!",
    "PR: Personal Record & Pull Request!",
    "I wear neon for high visibility!",
    "My sweat is open source!",
    "Quads of fire!",
    "Lifting: it's an algorithm!",
    "My posture is optimized!",
    "Ready to deploy gainz!",
    "No lag in my squats!",
    "Bench press = best press!",
    "I'm in compile state!",
    "Biceps > Brackets!",
    "Sweating out the syntax!",
    "Deadlifts are database schema!",
    "My core is multi-threaded!",
    "Running is a background service!",
    "Iron never lies!",
    "Chasing pixel PRs!",
    "Crushing iron!",
    "Quests cleared, gains secured!",
    "My abs are fully responsive!",
    "Leveling up is my stack trace!",
    "I squat, you watch!",
    "No pain, no mainframe!",
    "Coding at 1000 RPM!",
    "My power level is rising!",
    "Ready to rumble!",
    "My muscles are compiled AOT!",
    "Heavy lifts, clean codes!",
    "I don't skip leg day!",
    "Lifting is my loop!",
    "My stamina is infinite!",
    "Coder gainz!",
    "Slay the day!",
    "Zero exceptions found!",
    "My code is jacked!",
    "Buffering biceps...",
    "Muscles loaded: 100%!",
    "Stack overflow in my quads!",
    "Outrun the bugs!",
    "PR merged successfully!",
    "Let's get this gainz!"
  ];

  void _onDayTapped(String dayName, bool isToday, bool isFuture, double progress) {
    AppTheme.tap();
    final rand = Random();
    final weekday = DateTime.now().weekday;
    final isWeekend = weekday == 6 || weekday == 7;
    final jokeChance = isWeekend ? 0.80 : 0.35;

    if (rand.nextDouble() < jokeChance) {
      final joke = _getRandomUniqueJoke();
      _say(joke, stayDuration: const Duration(seconds: 3));
    } else {
      _say("$dayName!", stayDuration: const Duration(seconds: 1));
    }
  }
  
  bool get _isNight {
    final hour = DateTime.now().hour;
    return hour >= 22 || hour < 5;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 22) return 'Good Evening,';
    return 'Go To Sleep,';
  }

  @override
  void initState() {
    super.initState();
    
    // Calculate max weeks since user joined to prevent swiping prior to account creation
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final startOfDay = DateTime(now.year, now.month, now.day);
    final sundayIndex = todayWeekday == 7 ? 0 : todayWeekday;
    final todaySunday = startOfDay.subtract(Duration(days: sundayIndex));
    
    final joinDateStr = Storage.getData('join_date');
    DateTime joinDate;
    if (joinDateStr != null) {
      joinDate = DateTime.parse(joinDateStr);
    } else {
      joinDate = now;
      Storage.saveData('join_date', now.toIso8601String());
    }
    
    final joinWeekday = joinDate.weekday;
    final joinSundayIndex = joinWeekday == 7 ? 0 : joinWeekday;
    final joinSunday = DateTime(joinDate.year, joinDate.month, joinDate.day)
        .subtract(Duration(days: joinSundayIndex));
        
    final diffDays = todaySunday.difference(joinSunday).inDays;
    final int weeksPassed = (diffDays / 7).round();
    final int maxWeeks = weeksPassed.clamp(0, 3);
    
    _activeWeekIndex = maxWeeks; // Start on the rightmost page (current week)
    _weeklyPageController = PageController(initialPage: maxWeeks);
    _load();
    final weekday = DateTime.now().weekday;
    final isWeekend = weekday == 6 || weekday == 7;
    _playerAnim = isWeekend ? 'Idle' : (_isNight ? 'Stunned' : 'Run');
    _playerAnimId++;
    if (isWeekend) {
      final rand = Random();
      final List<WeekendQuestion> shuffled = List.from(_weekendPool)..shuffle(rand);
      _currentWeekendQuestions = shuffled.take(3).toList();
    }

    _dailyQuestsListenable = Storage.watch(Storage.dailyQuestsKey);
    _dailyQuestsListenable?.addListener(_onStorageChange);
    _startIdleChatter();
    _resetUserTouchTimer();
  }

  void _onStorageChange() {
    if (mounted) {
      setState(() {
        _load();
      });
    }
  }

  void _load() {
    try {
      if (mounted) {
        setState(() {
          _s = Storage.getUserStats();
          _profileImagePath = Storage.getProfileImage();
        });
      }
    } catch (e) {
      debugPrint('Home load error: $e');
    }
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _typewriterTimer?.cancel();
    _idleChatterTimer?.cancel();
    _touchIdleTimer?.cancel();
    _weeklyPageController.dispose();
    _dailyQuestsListenable?.removeListener(_onStorageChange);
    super.dispose();
  }

  Widget _buildWeeklyQuestProgressRow() {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Mon, ... 7 = Sun
    final int todayIndex = todayWeekday == 7 ? 0 : todayWeekday;

    // Full 7 days of the week starting on Sunday (index 0) through Saturday (index 6)
    final List<int> days = [0, 1, 2, 3, 4, 5, 6];

    // Determine weeks passed since account join date
    final joinDateStr = Storage.getData('join_date');
    DateTime joinDate;
    if (joinDateStr != null) {
      joinDate = DateTime.parse(joinDateStr);
    } else {
      joinDate = now;
    }
    
    final joinWeekday = joinDate.weekday;
    final joinSundayIndex = joinWeekday == 7 ? 0 : joinWeekday;
    final joinSunday = DateTime(joinDate.year, joinDate.month, joinDate.day)
        .subtract(Duration(days: joinSundayIndex));

    final currentSundayIndex = todayWeekday == 7 ? 0 : todayWeekday;
    final todaySunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentSundayIndex));
        
    final diffDays = todaySunday.difference(joinSunday).inDays;
    final int weeksPassed = (diffDays / 7).round();
    final int maxWeeks = weeksPassed.clamp(0, 3);

    DateTime dateForIndex(int idx, int weekOffset) {
      final todayStart = DateTime(now.year, now.month, now.day);
      return todayStart
          .subtract(Duration(days: currentSundayIndex + (weekOffset * 7)))
          .add(Duration(days: idx));
    }

    String getDayLetter(int idx) {
      switch (idx) {
        case 0: return 'S';
        case 1: return 'M';
        case 2: return 'T';
        case 3: return 'W';
        case 4: return 'T';
        case 5: return 'F';
        case 6: return 'S';
        default: return '';
      }
    }

    String getDayName(int idx) {
      switch (idx) {
        case 0: return 'Sunday';
        case 1: return 'Monday';
        case 2: return 'Tuesday';
        case 3: return 'Wednesday';
        case 4: return 'Thursday';
        case 5: return 'Friday';
        case 6: return 'Saturday';
        default: return '';
      }
    }

    double getQuestProgress(int idx, int weekOffset) {
      final date = dateForIndex(idx, weekOffset);
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      if (weekOffset == 0 && idx == todayIndex) {
        final quests = Storage.getDailyQuests();
        final total = quests.length;
        final completed = quests.where((q) => q.completed).length;
        final todayCompleted = total > 0 && total == completed;

        if (todayCompleted) {
          final history = Map<String, bool>.from(Storage.getData('quest_completion_history') ?? {});
          if (history[key] != true) {
            history[key] = true;
            Storage.saveData('quest_completion_history', history);
          }
        }
        return total > 0 ? (completed.toDouble() / total.toDouble()) : 0.0;
      }

      final history = Map<String, bool>.from(Storage.getData('quest_completion_history') ?? {});
      final completed = history[key] ?? false;
      return completed ? 1.0 : 0.0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.accent, width: 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY QUEST PROGRESS',
                style: AppTheme.label().copyWith(
                  color: AppTheme.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              // top right dots squared dots indicator (only show if history pages exist)
              if (maxWeeks > 0)
                Row(
                  children: List.generate(maxWeeks + 1, (index) {
                    final isActive = (maxWeeks - _activeWeekIndex) == index;
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accent : AppTheme.text2.withValues(alpha: 0.3),
                        shape: BoxShape.rectangle, // "squared dots"
                      ),
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: PageView.builder(
              controller: _weeklyPageController,
              onPageChanged: (idx) {
                setState(() {
                  _activeWeekIndex = idx;
                });
              },
              itemCount: maxWeeks + 1,
              itemBuilder: (context, index) {
                // Invert swipe page mapping so that page index 0 is the oldest week,
                // and the rightmost page is the current active week.
                final int weekOffset = maxWeeks - index;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: days.map((d) {
                    final isToday = (weekOffset == 0) && (d == todayIndex);
                    final isFuture = (weekOffset == 0) && (d > todayIndex);
                    final double progress = getQuestProgress(d, weekOffset);
                    final completed = progress >= 1.0;
                    final letter = getDayLetter(d);
                    final name = getDayName(d);

                    // Precise color states based on User specifications:
                    Color borderColor;
                    Color backgroundColor;
                    Color textColor;

                    if (isToday) {
                      if (completed) {
                        borderColor = AppTheme.green;
                        backgroundColor = AppTheme.green.withValues(alpha: 0.18);
                      } else {
                        borderColor = Colors.blue;
                        backgroundColor = Colors.blue.withValues(alpha: 0.15);
                      }
                      textColor = AppTheme.accent; // lighted up active day
                    } else if (isFuture) {
                      borderColor = AppTheme.line.withValues(alpha: 0.25);
                      backgroundColor = AppTheme.surface.withValues(alpha: 0.2);
                      textColor = AppTheme.text2.withValues(alpha: 0.5);
                    } else {
                      // Past days in current week or any days in previous weeks:
                      if (completed) {
                        borderColor = AppTheme.green.withValues(alpha: 0.6);
                        backgroundColor = AppTheme.surface.withValues(alpha: 0.4);
                      } else {
                        borderColor = AppTheme.red.withValues(alpha: 0.4);
                        backgroundColor = AppTheme.surface.withValues(alpha: 0.4);
                      }
                      textColor = AppTheme.text2.withValues(alpha: 0.8);
                    }

                    return GestureDetector(
                      onTap: () => _onDayTapped(name, isToday, isFuture, progress),
                      child: Tooltip(
                        message: '$name: ${completed ? "Completed" : "Not Completed"}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          width: isToday ? 44 : 34,
                          height: isToday ? 44 : 34,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomPaint(
                            painter: ProgressSquarePainter(
                              progress: progress,
                              progressColor: AppTheme.green,
                              backgroundColor: borderColor,
                              strokeWidth: isToday ? 2.5 : 1.5,
                              borderRadius: 10,
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: AppTheme.h3().copyWith(
                                  fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                                  fontSize: isToday ? 16 : 13,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_s == null) return const Center(child: CircularProgressIndicator());
    final s = _s!;
    final xpNeeded = RankSystem.getXpNeededForNextLevel(s.rank);
    final progress = (xpNeeded > 0 ? (s.xp / xpNeeded) : 0.0).clamp(0.0, 1.0).toDouble();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetUserTouchTimer(),
      child: Stack(
      children: [
        CustomScrollView(
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar + Info Column
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accent, width: 1.5),
                            image: _profileImagePath != null &&
                                    _profileImagePath!.isNotEmpty &&
                                    File(_profileImagePath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(_profileImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImagePath == null ||
                                  _profileImagePath!.isEmpty ||
                                  !File(_profileImagePath!).existsSync()
                              ? Icon(Icons.person_rounded,
                                  color: AppTheme.text3, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting,
                                style: AppTheme.caption(
                                    color: _greeting.contains('Sleep')
                                        ? AppTheme.white
                                        : AppTheme.text2)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(Storage.getCurrentUser() ?? 'Athlete',
                                    style: AppTheme.h1().copyWith(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text('Lv.${s.level}',
                                    style: AppTheme.mono(
                                            color: AppTheme.accent, size: 12)
                                        .copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // XP Progress Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 140,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: AppTheme.line,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Stack(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 600),
                                        width: 140 * progress,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                            AppTheme.accent,
                                            AppTheme.cyan
                                          ]),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                                color: AppTheme.accent
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 4)
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Rank ${s.rank} - ${s.xp}/$xpNeeded XP',
                                    style: AppTheme.caption(color: AppTheme.text2)
                                        .copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),



                    // Inventory Button
                    SGTouchable(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.line, width: 1.5),
                        ),
                        child: Icon(Icons.backpack_rounded,
                            size: 20, color: AppTheme.text1),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Player Card (Full Width)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: AppTheme.accent, width: 2.0),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Ground Line
                      Positioned(
                        bottom: 30, left: 20, right: 20,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppTheme.line.withValues(alpha: 0),
                              AppTheme.accent.withValues(alpha: 0.6),
                              AppTheme.line.withValues(alpha: 0),
                            ]),
                          ),
                        ),
                      ),

                      // Player Model
                      Positioned(
                        bottom: 30, left: 0, right: 0, height: 260,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Player(
                            key: ValueKey('$_playerAnim-$_playerAnimId'),
                            animation: _playerAnim,
                            fps: (_playerAnim == 'Run' || _idleMoves.contains(_playerAnim)) ? 12.0 : 8.0,
                            size: 260.0,
                            loop: _playerAnim == 'Run' || _playerAnim == 'Stunned' || _playerAnim == 'Idle',
                            onComplete: () {
                              if (mounted) {
                                if (_isPlayingCombo) {
                                  _playNextQueueAnimation();
                                } else {
                                  setState(() {
                                    final weekday = DateTime.now().weekday;
                                    final isWeekend = weekday == 6 || weekday == 7;
                                    _playerAnim = isWeekend ? 'Idle' : (_isNight ? 'Stunned' : 'Run');
                                    _playerAnimId++;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ),

                      // Sleep Zs
                      if (_isNight && _playerAnim == 'Stunned')
                        const Positioned.fill(child: _SleepZs()),

                      // Talking Comic Speech Bubble (Positioned right of the player head, with full wrap boundary)
                      if (_bubbleMessage != null)
                        Positioned(
                          bottom: 110,
                          left: MediaQuery.of(context).size.width / 2 + 25,
                          right: 16,
                          child: CustomPaint(
                            painter: ComicBubblePainter(
                              color: AppTheme.surface.withValues(alpha: 0.95),
                              borderColor: AppTheme.accent,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16), // Extra bottom padding for the tail
                              child: Text(
                                _typedBubbleMessage,
                                style: AppTheme.body().copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.text1,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Talk Button in Player Card (Bottom Right, Weekend only)
                      if (DateTime.now().weekday == 6 || DateTime.now().weekday == 7)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: SGTouchable(
                            onTap: () {
                              AppTheme.tap();
                              setState(() {
                                _isDialogueOpen = !_isDialogueOpen;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isDialogueOpen ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isDialogueOpen ? AppTheme.accent : AppTheme.line,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.forum_rounded,
                                size: 18,
                                color: _isDialogueOpen ? AppTheme.black : AppTheme.text1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Weekend Dialogue Panel
            if ((DateTime.now().weekday == 6 || DateTime.now().weekday == 7) && _isDialogueOpen)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.forum_rounded, color: AppTheme.accent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "CHOOSE A QUESTION",
                                  style: AppTheme.mono(color: AppTheme.accent, size: 10)
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SGTouchable(
                              onTap: () {
                                AppTheme.tap();
                                setState(() {
                                  _isDialogueOpen = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.black.withValues(alpha: 0.3),
                                ),
                                child: Icon(Icons.close_rounded, color: AppTheme.text2, size: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_currentWeekendQuestions.isEmpty)
                          Center(
                            child: Text(
                              "No questions loaded.",
                              style: AppTheme.caption(color: AppTheme.text3),
                            ),
                          )
                        else
                          ..._currentWeekendQuestions.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final q = entry.value;
                            final isSelected = _selectedQuestionIndex == idx;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: SGTouchable(
                                onTap: _selectedQuestionIndex != null
                                    ? null // Disable taps during active transition
                                    : () {
                                        AppTheme.tap();
                                        setState(() {
                                          _selectedQuestionIndex = idx;
                                        });
                                        _say(q.answer, stayDuration: const Duration(seconds: 8));
                                        
                                        Timer(const Duration(seconds: 2), () {
                                          if (mounted) {
                                            setState(() {
                                              _selectedQuestionIndex = null;
                                              _refreshWeekendQuestions();
                                            });
                                          }
                                        });
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(seconds: 2),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2196F3) : AppTheme.line, // Blue vs gray
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    q.question,
                                    style: AppTheme.body().copyWith(
                                      fontSize: 11,
                                      color: isSelected ? const Color(0xFF2196F3) : AppTheme.text2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),

            // Weekly Progress Squares Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                child: _buildWeeklyQuestProgressRow(),
              ),
            ),
          ],
        ),

      ],
    ),
  );
}
}



class _SleepZs extends StatefulWidget {
  const _SleepZs();
  @override
  State<_SleepZs> createState() => _SleepZsState();
}

class _SleepZsState extends State<_SleepZs> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: List.generate(3, (i) {
            final double t = (_ctrl.value + (i / 3)) % 1.0;
            return Positioned(
              bottom: 80 + (t * 50),
              left: MediaQuery.of(context).size.width / 2 + 10 + (sin(t * 4) * 15),
              child: Opacity(
                opacity: (1.0 - t).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.6 + (t * 0.4),
                  child: Text(
                    'Z',
                    style: AppTheme.mono(
                      color: i % 2 == 0 ? Colors.purpleAccent : Colors.blueAccent,
                      size: 12 + (i * 4).toDouble(),
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class ProgressSquarePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double borderRadius;

  ProgressSquarePainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (progress <= 0.0) {
      paint.color = backgroundColor;
      canvas.drawRRect(rrect, paint);
    } else if (progress >= 1.0) {
      paint.color = progressColor;
      canvas.drawRRect(rrect, paint);
    } else {
      paint.shader = SweepGradient(
        colors: [progressColor, progressColor, backgroundColor, backgroundColor],
        stops: [0.0, progress, progress, 1.0],
        transform: const GradientRotation(-pi / 2), // Start at top center of the square
      ).createShader(rect);
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ProgressSquarePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class ComicBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double strokeWidth;

  ComicBubblePainter({
    required this.color,
    required this.borderColor,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double r = 8.0; // corner radius
    final double arrowW = 8.0; // arrow width
    final double arrowH = 8.0; // arrow height

    final double w = size.width;
    final double h = size.height - arrowH;

    // Top-left corner
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    // Right side
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    // Bottom side
    path.lineTo(arrowW + 4, h);
    
    // The triangular arrow pointing down-left towards player head
    path.lineTo(0, size.height);
    path.lineTo(4, h - 2);
    
    // Left side
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ComicBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class WeekendQuestion {
  final String question;
  final String answer;
  const WeekendQuestion(this.question, this.answer);
}
