import 'dotenv/config';
import { GoogleGenerativeAI } from '@google/generative-ai'; // Se o pacote base não estiver instalado, a langchain depende dele.
import { GoogleGenerativeAIEmbeddings } from '@langchain/google-genai';

async function listModels() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.log("Sem API Key.");
    return;
  }
  
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`);
    const data = await response.json();
    console.log("Modelos suportados:");
    const embeddingModels = (data as any).models.filter((m: any) => m.supportedGenerationMethods.includes('generateContent'));
    embeddingModels.forEach((m: any) => {
      console.log(`- ${m.name} (Methods: ${m.supportedGenerationMethods.join(', ')})`);
    });
  } catch (err) {
    console.error("Erro:", err);
  }
}

listModels();
