// Book of Answers utility
// This file contains the answers from the mystical "Book of Answers"

/**
 * The Book of Answers is a collection of mystical, thought-provoking responses
 * that provide guidance and reflection to unspoken questions.
 * Users mentally ask a question and receive one of these answers.
 */

export const getBookAnswer = (): string => {
  // Collection of answers inspired by "The Book of Answers" concept
  const answers = [
    "是的，毫无疑问。",
    "相信你的直觉。",
    "现在不是时候。",
    "宇宙已经安排好了。",
    "耐心等待，时机即将到来。",
    "不要强求，顺其自然。",
    "放手，让它去吧。",
    "是时候改变方向了。",
    "这个问题的答案就在你心中。",
    "寻求更多信息后再决定。",
    "绝对不要。",
    "现在就行动。",
    "接受它，然后前进。",
    "你已经知道答案了。",
    "这个决定将带来意想不到的结果。",
    "重新思考你的问题。",
    "寻求他人的建议。",
    "相信这个过程。",
    "答案将在梦中揭示。",
    "观察自然的征兆。",
    "是的，但不要操之过急。",
    "不，但不要放弃希望。",
    "暂时搁置这个问题。",
    "专注于当下。",
    "回顾过去的经验。",
    "这不是正确的问题。",
    "跟随你的心。",
    "这是一个转折点。",
    "答案就在你面前。",
    "勇敢地面对恐惧。",
    "等待更清晰的指引。",
    "信任这个旅程。",
    "接受不确定性。",
    "改变你的视角。",
    "这个问题需要更深入的思考。",
    "现在是行动的时候了。",
    "寻找平衡。",
    "放下过去。",
    "相信宇宙的时机。",
    "答案将在意想不到的地方出现。",
    "保持开放的心态。",
    "这个决定将影响你的未来道路。",
    "不要被表面现象迷惑。",
    "寻找内在的智慧。",
    "是的，如果你全心投入。",
    "不，除非情况发生变化。",
    "宇宙正在为你创造更好的机会。",
    "这个挑战是一份礼物。",
    "你比自己想象的更强大。",
    "答案在星光中闪烁。",
  ];
  
  // Return a random answer
  return answers[Math.floor(Math.random() * answers.length)];
};

// Get a more detailed, reflective follow-up to an answer
export const getAnswerReflection = (answer: string): string => {
  // Map of reflections for each answer type
  const reflections: Record<string, string[]> = {
    // Positive answers
    "是的，毫无疑问。": [
      "有时宇宙会给予明确的指引，这是一个清晰的信号。",
      "当道路如此清晰，勇敢前行是唯一的选择。",
      "确定性是一种礼物，珍视这一刻的清晰。"
    ],
    "相信你的直觉。": [
      "内在的声音往往比理性更能接近真相。",
      "直觉是灵魂的语言，它知道理性尚未发现的真理。",
      "最深刻的智慧常常以感觉的形式出现。"
    ],
    
    // Waiting answers
    "现在不是时候。": [
      "时机的重要性常被低估，耐心等待是一种智慧。",
      "有些种子需要更长的时间才能发芽，给它应有的时间。",
      "延迟并不意味着拒绝，只是宇宙的时间与我们的期望不同。"
    ],
    "耐心等待，时机即将到来。": [
      "等待的过程本身就是准备的一部分。",
      "即将到来的转变需要你完全准备好。",
      "黎明前的黑暗常常最为深沉。"
    ],
    
    // Default reflections for other answers
    "default": [
      "每个答案都是一面镜子，反射出提问者内心的真相。",
      "有时答案的价值不在于它的内容，而在于它引发的思考。",
      "智慧不在于获得确定的答案，而在于提出更好的问题。",
      "答案可能会随着时间的推移而揭示其更深层的含义。",
      "星辰的指引是微妙的，需要安静的心灵才能理解。"
    ]
  };
  
  // Get reflection for the specific answer or use default
  const specificReflections = reflections[answer] || reflections["default"];
  return specificReflections[Math.floor(Math.random() * specificReflections.length)];
}; 