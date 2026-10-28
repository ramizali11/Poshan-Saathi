class ChildProfile {
  final String id;
  final String name;
  final String gujaratiName;
  final int ageInMonths;
  final DateTime dob;
  final String gender; // 'Boy' or 'Girl'
  final double currentWeightKg;
  final double currentLengthCm;
  final String feedingStage;
  final String whoZone;
  final String anganwadiCenter;
  final String ashaWorkerName;
  final String abhaId;
  final String motherName;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.gujaratiName,
    required this.ageInMonths,
    required this.dob,
    required this.gender,
    required this.currentWeightKg,
    required this.currentLengthCm,
    required this.feedingStage,
    required this.whoZone,
    required this.anganwadiCenter,
    required this.ashaWorkerName,
    required this.abhaId,
    required this.motherName,
  });
}

class GrowthMeasurement {
  final String dateString;
  final int ageMonths;
  final double weightKg;
  final double lengthCm;
  final double zScore;
  final String eventType;
  final String workerName;
  final String notes;

  const GrowthMeasurement({
    required this.dateString,
    required this.ageMonths,
    required this.weightKg,
    required this.lengthCm,
    required this.zScore,
    required this.eventType,
    required this.workerName,
    required this.notes,
  });
}

class Meal {
  final String id;
  final String slotName;
  final String slotTime;
  final String title;
  final String gujaratiTitle;
  final String subtitle;
  final int prepMinutes;
  final int costInRupees;
  final String textureNote;
  final String absorptionTip;
  final String absorptionTipGujarati;
  final bool isLogged;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> cookingSteps;

  const Meal({
    required this.id,
    required this.slotName,
    required this.slotTime,
    required this.title,
    required this.gujaratiTitle,
    required this.subtitle,
    required this.prepMinutes,
    required this.costInRupees,
    required this.textureNote,
    required this.absorptionTip,
    required this.absorptionTipGujarati,
    this.isLogged = false,
    required this.tags,
    required this.ingredients,
    required this.cookingSteps,
  });
}

class RiskAlertItem {
  final String id;
  final String title;
  final String category;
  final String severity; // 'high', 'moderate', 'info'
  final String date;
  final String description;
  final String recommendation;
  final bool isReviewed;

  const RiskAlertItem({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.date,
    required this.description,
    required this.recommendation,
    this.isReviewed = false,
  });
}

class MockData {
  static final ChildProfile defaultChild = ChildProfile(
    id: 'aarav_1',
    name: 'Aarav Shah',
    gujaratiName: 'આરવ શાહ',
    ageInMonths: 14,
    dob: DateTime(2024, 12, 12),
    gender: 'Boy',
    currentWeightKg: 9.4,
    currentLengthCm: 77.2,
    feedingStage: 'Stage 3: Coarse Mash & Soft Finger Foods',
    whoZone: 'WHO Green Zone (50th Percentile)',
    anganwadiCenter: 'Sector 4 Center, Mandvi, Kutch',
    ashaWorkerName: 'Kavita Ben',
    abhaId: '91-8472-1049',
    motherName: 'Priya Shah',
  );

  static final List<GrowthMeasurement> growthHistory = [
    const GrowthMeasurement(
      dateString: '12 Feb 2026',
      ageMonths: 14,
      weightKg: 9.4,
      lengthCm: 77.2,
      zScore: 0.1,
      eventType: 'Anganwadi Session #4',
      workerName: 'Kavita Ben',
      notes: 'Active texture chewing observed. Good weight velocity (+0.3kg).',
    ),
    const GrowthMeasurement(
      dateString: '10 Jan 2026',
      ageMonths: 13,
      weightKg: 9.1,
      lengthCm: 75.8,
      zScore: 0.0,
      eventType: 'Mamta Divas Checkup',
      workerName: 'Kavita Ben',
      notes: 'Advised soft bajra porridge and moong dal khichdi.',
    ),
    const GrowthMeasurement(
      dateString: '08 Dec 2025',
      ageMonths: 12,
      weightKg: 8.8,
      lengthCm: 74.5,
      zScore: -0.1,
      eventType: 'Home Visit Record',
      workerName: 'Kavita Ben',
      notes: 'Completed 1 year. Vitamin A booster dose administered.',
    ),
    const GrowthMeasurement(
      dateString: '15 Oct 2025',
      ageMonths: 10,
      weightKg: 8.3,
      lengthCm: 72.1,
      zScore: 0.0,
      eventType: 'Routine Growth Check',
      workerName: 'Kavita Ben',
      notes: 'Stage 2 transition to semi-solid food.',
    ),
    const GrowthMeasurement(
      dateString: '14 Aug 2025',
      ageMonths: 8,
      weightKg: 7.6,
      lengthCm: 68.8,
      zScore: 0.1,
      eventType: 'Mamta Divas Checkup',
      workerName: 'Kavita Ben',
      notes: 'Complementary feeding initiation started well with ragi porridge.',
    ),
  ];

  static final List<Meal> todayMeals = [
    const Meal(
      id: 'm1',
      slotName: 'Morning Snack',
      slotTime: '9:30 AM',
      title: 'Mashed Papaya & Sprouted Ragi Sheera',
      gujaratiTitle: 'પપૈયું અને અંકુરિત રાગી શીરો',
      subtitle: 'Natural sweetness, High Calcium & Vitamin A',
      prepMinutes: 15,
      costInRupees: 15,
      textureNote: 'Smooth with fine ragi granules',
      absorptionTip: 'Papaya provides natural fruit enzymes aiding gentle digestion.',
      absorptionTipGujarati: 'પપૈયું પાચન સરળ બનાવે છે અને કુદરતી વિટામિન A પૂરું પાડે છે.',
      isLogged: true,
      tags: ['Calcium-Rich', 'Gentle Sweet', 'Vit A'],
      ingredients: [
        'Sprouted Ragi Flour (2 tbsp)',
        'Mashed Ripe Papaya (2 tbsp)',
        'Cow Ghee (1/2 tsp)',
        'Warm water or milk (1/2 cup)',
      ],
      cookingSteps: [
        'Roast ragi flour gently in ghee until fragrant.',
        'Add warm water and stir continuously on low flame.',
        'Once thickened, cool and fold in fresh mashed papaya.',
      ],
    ),
    const Meal(
      id: 'm2',
      slotName: 'Lunch (બપોરનું ભોજન)',
      slotTime: '12:30 PM',
      title: 'Vegetable Moong Dal Khichdi with Steamed Carrots & Desi Cow Ghee',
      gujaratiTitle: 'શાકભાજી મગની દાળની ખીચડી અને દેશી ઘી',
      subtitle: 'Iron-Rich, Balanced Plant Protein & Healthy Fats',
      prepMinutes: 20,
      costInRupees: 22,
      textureNote: 'Soft Coarse Mash (Do not blend to liquid)',
      absorptionTip:
          'Squeeze 3 drops of fresh lemon or serve with grated amla to boost plant-iron absorption by up to 300%. Avoid milk at this feed.',
      absorptionTipGujarati:
          'જમતા પહેલાં ૩ ટીપાં તાજા લીંબુનો રસ ઉમેરવાથી દાળનું લોહતત્વ બાળક ઝડપથી પચાવી શકે છે.',
      isLogged: true,
      tags: ['Iron-Rich (આયર્ન)', 'Soft Coarse Mash', 'ICMR-Aligned'],
      ingredients: [
        'Yellow moong dal (પીળી મગની દાળ) Pre-soaked 15m — 2 tbsp',
        'Broken raw rice (ટુકડા ચોખા) — 2 tbsp',
        'Tender carrot diced small (ઝીણું ગાજર) — 1 tbsp',
        'Turmeric & roasted cumin (હળદર અને જીરું) — 1 pinch each',
        'Pure Desi Cow Ghee (ગાયનું ઘી) — 1 tsp',
        'Clean filtered water — 1 cup',
      ],
      cookingSteps: [
        'Cleanse & Soak: Wash moong dal and broken rice thoroughly 3 times. Soak 15 minutes.',
        'Gentle Pressure Cooking: Add grains, carrots, water, turmeric and cumin. Pressure cook 3-4 whistles.',
        'Texture Critical: Fork-mash softly with ghee. DO NOT blend into liquid soup — soft lumps train essential oral-motor chewing.',
      ],
    ),
    const Meal(
      id: 'm3',
      slotName: 'Evening Snack',
      slotTime: '5:00 PM',
      title: 'Sprouted Moong Soup & Soft Roti Strips',
      gujaratiTitle: 'મગનું સૂપ અને રોટલીની પટ્ટીઓ',
      subtitle: 'Easy finger food practice for oral development',
      prepMinutes: 15,
      costInRupees: 12,
      textureNote: 'Finger food practice, choking-safe thin strips',
      absorptionTip: 'Light cumin tempering stimulates toddler appetite naturally.',
      absorptionTipGujarati: 'જીરાનો હળવો વઘાર બાળકની ભૂખ વધારે છે.',
      isLogged: false,
      tags: ['Finger Food', 'High Protein'],
      ingredients: [
        'Sprouted green moong boiled (3 tbsp)',
        'Soft whole wheat roti strip (1 piece)',
        'Cumin seeds & pinch of salt',
        'Ghee (1/2 tsp)',
      ],
      cookingSteps: [
        'Boil sprouted moong until completely soft and tender.',
        'Mash slightly with spoon in warm water with cumin tempering.',
        'Serve with soft cut strips of warm roti for self-feeding practice.',
      ],
    ),
    const Meal(
      id: 'm4',
      slotName: 'Dinner (સાંજનું ભોજન)',
      slotTime: '7:30 PM',
      title: 'Bottle Gourd (Dudhi) & Rice Porridge with Roasted Cumin',
      gujaratiTitle: 'દૂધી-ચોખાની હળવી રાબ',
      subtitle: 'Hydrating, easy to digest for peaceful night sleep',
      prepMinutes: 15,
      costInRupees: 14,
      textureNote: 'Smooth porridge consistency',
      absorptionTip: 'Easy gastrointestinal transit prevents infant night colic.',
      absorptionTipGujarati: 'દૂધી પેટ માટે ખૂબ હળવી છે અને શાંત ઊંઘ આપે છે.',
      isLogged: false,
      tags: ['Easy Digest', 'Hydrating'],
      ingredients: [
        'Fresh grated dudhi / bottle gourd (2 tbsp)',
        'Rice flour or broken rice (2 tbsp)',
        'Cumin powder (pinch)',
        'Ghee (1/2 tsp)',
      ],
      cookingSteps: [
        'Sauté grated dudhi in ghee for 2 minutes.',
        'Add rice and water, simmer until completely translucent and soft.',
        'Season with roasted cumin and serve warm.',
      ],
    ),
  ];

  static final List<RiskAlertItem> activeAlerts = [
    const RiskAlertItem(
      id: 'a1',
      title: 'Weight Gain Velocity Plateau',
      category: 'Growth Velocity Review',
      severity: 'moderate',
      date: '12 Feb 2026',
      description:
          'Aarav has gained +150g over the last 45 days, which is slightly below standard trajectory for the 12-14 month transition window.',
      recommendation:
          'Review complementary food energy density (add 1/2 tsp ghee/oil) and schedule routine growth check at next Mamta Divas on 26 Feb.',
    ),
    const RiskAlertItem(
      id: 'a2',
      title: 'Reported Feeding Hesitation on Coarse Mash',
      category: 'Feeding & Texture Acceptance',
      severity: 'moderate',
      date: '10 Feb 2026',
      description:
          'Parent logged reluctance during lunch feeds with textured moong dal khichdi. Gradual texture transition helps prevent oral-motor delay.',
      recommendation:
          'Try finger foods like soft steamed carrot batons alongside mashed khichdi. Avoid blending into liquid soup.',
    ),
    const RiskAlertItem(
      id: 'a3',
      title: 'Upcoming Monthly Anganwadi Weigh-in',
      category: 'Growth Monitoring Due',
      severity: 'info',
      date: 'Due 26 Feb 2026',
      description:
          'Next Mamta Divas session at Sector 4 center is approaching. Regular weight and height recording supports early detection of faltering.',
      recommendation:
          'Mandvi Sector 4 Center • 9:30 AM - 1:00 PM. Bring Mother and Child Protection (MCP) card.',
    ),
  ];
}

