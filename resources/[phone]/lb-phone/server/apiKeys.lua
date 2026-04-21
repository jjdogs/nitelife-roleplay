-- Webhook for instapic posts, recommended to be a public channel
INSTAPIC_WEBHOOK = "https://discord.com/api/webhooks/"
-- Webhook for birdy posts, recommended to be a public channel
BIRDY_WEBHOOK = "https://discord.com/api/webhooks/"

-- Discord webhook or API key for server logs
-- We recommend https://fivemanage.com/ for logs. Use code "LBLOGS" for 20% off the Logs Pro plan
LOGS = {
    Default = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3", -- set to false to disable
    Calls = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Messages = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    InstaPic = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Birdy = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    YellowPages = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Marketplace = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Mail = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Wallet = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    DarkChat = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Services = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Crypto = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Trendy = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Uploads = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3" -- all camera uploads will go here
}

DISCORD_TOKEN = nil -- you can set a discord bot token here to get the players discord avatar for logs

-- Set your API keys for uploading media here.
-- Please note that the API key needs to match the correct upload method defined in Config.UploadMethod.
-- The default upload method is Fivemanage
-- You can get your API keys from https://fivemanage.com/
-- Use code LBPHONE10 for 10% off on Fivemanage
-- A video tutorial for how to set up Fivemanage can be found here: https://www.youtube.com/watch?v=y3bCaHS6Moc
API_KEYS = {
    Video = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Image = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
    Audio = "hCXQQWigpvR09n2HmlwlXYzyGxIO6zQ3",
}

-- Here you can set your credentials for Config.DynamicWebRTC
-- This is needed if video calls or InstaPic live streams are not working
-- You can get your credentials from https://dash.cloudflare.com/?to=/:account/realtime/turn/overview
WEBRTC = {
    TokenID = nil,
    APIToken = nil,
}
