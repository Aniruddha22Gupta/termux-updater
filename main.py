import os
import discord
from discord import app_commands
from discord.ext import commands

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

TOKEN = os.environ.get("DISCORD_TOKEN")

if not TOKEN:
    print("Error: Missing DISCORD_TOKEN in environment variables or .env file!")
    exit(1)

class InputBot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        intents.message_content = True
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        await self.tree.sync()

bot = InputBot()

feedback_CHANNEL_ID = 1472268841731096810

@bot.event
async def on_ready():
    print(f"🤖 Bot is logged in and ready as {bot.user}")

@bot.tree.command(name="feedback", description="Submit feedback")
@app_commands.describe(
    topic="What is your feedback about?",
    message="Your detailed message"
)
async def feedback(interaction: discord.Interaction, topic: str, message: str):
    await interaction.response.defer(ephemeral=True)
    
    channel = bot.get_channel(feedback_CHANNEL_ID)
    
    if channel is None:
        try:
            channel = await bot.fetch_channel(feedback_CHANNEL_ID)
        except (discord.NotFound, discord.Forbidden):
            await interaction.followup.send(
                "Error: feedback channel could not be found or access is restricted.", 
                ephemeral=True
            )
            return

    await channel.send(
        f"📩 **New feedback Received! <@&1433856361120268318>**\n"
        f"**From:** {interaction.user.mention}\n"
        f"**Topic:** {topic}\n"
        f"**Message:** {message}"
    )

    await interaction.followup.send(
        "Thank you! Your feedback has been submitted.", 
        ephemeral=True
    )

if __name__ == "__main__":
    bot.run(TOKEN)