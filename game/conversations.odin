package karl2d_game

import hm "core:/container/handle_map"

Conversation_Handle :: distinct hm.Handle32
conversationEntities: hm.Dynamic_Handle_Map(ConversationData, Conversation_Handle)

ConversationData :: struct {
	handle:       Conversation_Handle,
	dialogue:     [dynamic]string,
	name:         string,
	current_line: int,
}

@(private = "file")
ConversationFile: struct {
	pendingAdvanceHandle: Conversation_Handle,
} = {}

// setup a name of the person to talk to
add_conversation :: proc(name: string) -> Conversation_Handle {
	handle := hm.add(&conversationEntities, ConversationData{name = name})
	debugf("CONVERSATION: Created conversation with handle %v and name %v", handle, name)
	return handle
}

// add dialogue to a conversation, returns true if successful
add_conversation_dialogue :: proc(
	conversation: Conversation_Handle,
	line_number: int,
	dialogue: string,
) -> bool {
	if line_number < 0 {
		warnf("CONVERSATION: Invalid line_number %d", line_number)
		return false
	}

	if conversation, ok := hm.get(&conversationEntities, conversation); ok {
		for len(conversation.dialogue) <= line_number {
			append(&conversation.dialogue, "")
		}

		conversation.dialogue[line_number] = dialogue
		debugf(
			"CONVERSATION: Added dialogue to conversation %v at line %d: %v",
			conversation.handle,
			line_number,
			dialogue,
		)
		return true
	} else {
		warnf("CONVERSATION: Failed to add dialogue, invalid conversation handle %v", conversation)
		return false
	}
}

flush_all_conversations :: proc() {
	hm.clear(&conversationEntities)
}

advance_conversation_line :: proc(conversation_handle: Conversation_Handle) {
	if conversation, ok := hm.get(&conversationEntities, conversation_handle); ok {
		if len(conversation.dialogue) == 0 do return
		conversation.current_line = (conversation.current_line + 1) % len(conversation.dialogue)
	}
}

handle_conversation :: proc(npc_data: ^NPCData) {
	if npc_data == nil do return

	if npc_data.disposition != .Friendly {
		return
	}

	conversation_handle := npc_data.conversation_handle
	if !hm.is_valid(&conversationEntities, conversation_handle) {
		debugf("CONVERSATION: NPC has no valid conversation handle, skipping")
		return
	}

	conversation := hm.get(&conversationEntities, conversation_handle)
	if len(conversation.dialogue) == 0 {
		debugf("CONVERSATION: Conversation %v has no dialogue lines", conversation_handle)
		return
	}

	if conversation.current_line < 0 || conversation.current_line >= len(conversation.dialogue) {
		conversation.current_line = 0
	}

	ConversationFile.pendingAdvanceHandle = conversation_handle

	init_message_prompt(proc() {
			advance_conversation_line(ConversationFile.pendingAdvanceHandle)
		}, conversation.name, conversation.dialogue[conversation.current_line], "Next")
}
