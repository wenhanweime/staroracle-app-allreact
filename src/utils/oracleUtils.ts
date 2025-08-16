// This function simulates generating a mystical, poetic response
// In a real app, this would connect to an AI service
export const generateOracleResponse = (): string => {
  const responses = [
    "The stars whisper of paths untaken, yet your journey remains true to your heart's calling.",
    "Like the moon's reflection on water, what you seek is both there and not there. Look deeper.",
    "Ancient light travels to reach your eyes; patience will reveal what haste conceals.",
    "The cosmos spins patterns of possibility. Your question already contains its answer.",
    "Celestial bodies dance in harmony despite distance. Find your rhythm in life's grand ballet.",
    "As galaxies spiral through the void, your path winds through darkness toward distant light.",
    "The nebula of your thoughts contains the seeds of stars yet unborn. Nurture them.",
    "Time flows like stellar winds, shaping the landscape of your existence into forms yet unknown.",
    "The void between stars is not empty but full of potential. Embrace the spaces in your life.",
    "Your question echoes across the cosmos, returning with wisdom carried on starlight.",
    "The universe expands without destination. Your journey needs no justification beyond itself.",
    "Constellations are patterns we impose on chaos. Create meaning from the random stars of experience.",
    "The light you see began its journey long ago. Trust in what is revealed, even if delayed.",
    "Cosmic dust becomes stars becomes dust again. All transformations are possible for you.",
    "The gravity of your intentions pulls experiences into orbit around you. Choose wisely what you attract.",
  ];
  
  return responses[Math.floor(Math.random() * responses.length)];
};