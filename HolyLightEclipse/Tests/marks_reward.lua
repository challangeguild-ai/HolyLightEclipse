-- Marks observations only use explicit native messages; no synthetic currency balance.
getglobal=function(k) return _G[k] end
HLE_DB={enabled=true,showLoot=false}
assert(loadfile("Core.lua"))()
assert(loadfile("Loot.lua"))()
assert(HLE.marksBalance==nil)
assert(HLE.LootEvent("CHAT_MSG_SYSTEM","You earn 0.5 marks (85.7 in all)."))
assert(HLE.marksBalance==85.7,"Native total was not preserved")
assert(HLE.LootEvent("CHAT_MSG_SYSTEM","You earn 1 mark (86.7 in all)."))
assert(HLE.marksBalance==86.7,"Singular mark reward was missed")
assert(HLE.LootEvent("CHAT_MSG_SYSTEM","You earn 1 mark (87.7 in all)."))
assert(HLE.marksBalance==87.7)
assert(not HLE.LootEvent("CHAT_MSG_SYSTEM","Maybe you earned 50 marks"))
assert(HLE.marksBalance==87.7,"Unverified text changed Marks balance")
print("Marks rewards: exact native message only; observed total preserved")
