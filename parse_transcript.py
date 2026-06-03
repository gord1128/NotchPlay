import json

log_path = "/Users/hyeonm9/.gemini/antigravity/brain/0a012dc9-1ac4-460b-b6a2-5cceddbc6ac7/.system_generated/logs/transcript.jsonl"
out_path = "Conversation_History.md"

with open(log_path, "r", encoding="utf-8") as f, open(out_path, "w", encoding="utf-8") as out:
    out.write("# 💬 NotchPlay 프로젝트 대화 기록\n\n")
    
    for line in f:
        if not line.strip(): continue
        try:
            data = json.loads(line)
        except:
            continue
            
        src = data.get("source", "")
        ctype = data.get("type", "")
        content = data.get("content", "")
        
        if src == "USER_EXPLICIT" and ctype == "USER_INPUT":
            # Extract actual user request from <USER_REQUEST> tags if present
            if "<USER_REQUEST>" in content and "</USER_REQUEST>" in content:
                req = content.split("<USER_REQUEST>")[1].split("</USER_REQUEST>")[0].strip()
                if req:
                    out.write(f"### 👤 사용자\n{req}\n\n---\n\n")
            else:
                out.write(f"### 👤 사용자\n{content.strip()}\n\n---\n\n")
                
        elif src == "MODEL" and ctype == "PLANNER_RESPONSE":
            if content.strip():
                out.write(f"### 🤖 AI (Antigravity)\n{content.strip()}\n\n---\n\n")

print(f"Successfully saved to {out_path}")
