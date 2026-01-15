import google.generativeai as genai
import gradio as gr
from config import Config

# Load configuration
API_KEY = Config.get_gemini_api_key()
MODEL_NAME = Config.get_gemini_model()

if not API_KEY:
    print("⚠️  Warning: GEMINI_API_KEY not set!")
    print("Get your free API key from: https://aistudio.google.com/apikey")
    print("Set it in .env file or as environment variable:")
    print("  - GEMINI_API_KEY=your-api-key-here")
    print("  - Or TF_VAR_gemini_api_key=your-api-key-here")

genai.configure(api_key=API_KEY)

# Initialize the model
print(f"🤖 Using model: {MODEL_NAME}")
model = genai.GenerativeModel(MODEL_NAME)

# Store conversation history
chat_session = None


def start_new_chat():
    """Start a new chat session."""
    global chat_session
    chat_session = model.start_chat(history=[])
    return []


def respond(message, history):
    """Send message to Gemini and get response."""
    global chat_session
    
    if chat_session is None:
        chat_session = model.start_chat(history=[])
    
    try:
        response = chat_session.send_message(message)
        return response.text
    except Exception as e:
        return f"Error: {str(e)}"


# Create Gradio interface
with gr.Blocks(
    title="Gemini Chatbot",
    theme=gr.themes.Soft(
        primary_hue="emerald",
        secondary_hue="slate",
        neutral_hue="slate",
        font=gr.themes.GoogleFont("Outfit"),
    ),
    css="""
        .gradio-container {
            max-width: 800px !important;
            margin: auto !important;
        }
        .header {
            text-align: center;
            padding: 20px;
            background: linear-gradient(135deg, #059669 0%, #10b981 50%, #34d399 100%);
            border-radius: 16px;
            margin-bottom: 20px;
            color: white;
        }
        .header h1 {
            margin: 0;
            font-size: 2rem;
            font-weight: 700;
        }
        .header p {
            margin: 8px 0 0 0;
            opacity: 0.9;
        }
    """
) as demo:
    gr.HTML(f"""
        <div class="header">
            <h1>✨ Gemini Chatbot</h1>
            <p>Powered by Google's {MODEL_NAME}</p>
        </div>
    """)
    
    chatbot = gr.ChatInterface(
        fn=respond,
        type="messages",
        chatbot=gr.Chatbot(
            height=450,
            type="messages",
            placeholder="<strong>👋 Hello!</strong><br>I'm your AI assistant powered by Gemini. Ask me anything!",
        ),
        textbox=gr.Textbox(
            placeholder="Type your message here...",
            container=False,
            scale=7,
        ),
    )
    
    gr.Markdown(
        """
        ---
        <center style="color: #6b7280; font-size: 0.875rem;">
        Get your free API key from <a href="https://aistudio.google.com/apikey" target="_blank">Google AI Studio</a>
        </center>
        """,
        elem_classes="footer"
    )

if __name__ == "__main__":
    print("\n🚀 Starting Gemini Chatbot...")
    print("📍 Open http://localhost:7860 in your browser\n")
    demo.launch()
