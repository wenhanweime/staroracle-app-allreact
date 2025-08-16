// This function simulates generating a unique cosmic image for each star
// In a real app, this would connect to an AI image generation service
export const generateRandomStarImage = (): string => {
  // Array of cosmic-themed images from Pexels
  const cosmicImages = [
    'https://images.pexels.com/photos/1169754/pexels-photo-1169754.jpeg',
    'https://images.pexels.com/photos/1252890/pexels-photo-1252890.jpeg',
    'https://images.pexels.com/photos/1274260/pexels-photo-1274260.jpeg',
    'https://images.pexels.com/photos/1694000/pexels-photo-1694000.jpeg',
    'https://images.pexels.com/photos/1257860/pexels-photo-1257860.jpeg',
    'https://images.pexels.com/photos/1906658/pexels-photo-1906658.jpeg',
    'https://images.pexels.com/photos/1146134/pexels-photo-1146134.jpeg',
    'https://images.pexels.com/photos/1341279/pexels-photo-1341279.jpeg',
    'https://images.pexels.com/photos/816608/pexels-photo-816608.jpeg',
    'https://images.pexels.com/photos/1434608/pexels-photo-1434608.jpeg',
    'https://images.pexels.com/photos/1938348/pexels-photo-1938348.jpeg',
    'https://images.pexels.com/photos/1693095/pexels-photo-1693095.jpeg',
  ];
  
  // Return a random image from the array
  return cosmicImages[Math.floor(Math.random() * cosmicImages.length)];
};