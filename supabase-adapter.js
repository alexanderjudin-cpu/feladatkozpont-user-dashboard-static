/* ============================================================================
 *  HD Direkt — Feladatközpont · Supabase adat-réteg v2 (adapter)
 * ----------------------------------------------------------------------------
 *  CSAK EZT KELL KITÖLTENED A LIVE BEKÖTÉSHEZ (URL + anon key + board_key).
 *  Üres config → az app LOKÁLIS módban fut (localStorage), minden művelet megy,
 *  csak nem ír a DB-be. Service_role key SOHA nem kerülhet ide (csak anon + RLS).
 *
 *  Séma: task_center_schema_v2.sql · RLS: rls_policies_draft.sql
 *  View-k: v_task_cards_frontend, v_board_members
 *  RPC-k:  move_task_card, queue_agent_job, add_event
 *  Írás:   RLS dönt arról, mit írhat a user (assignee / creator / can_edit_all).
 * ========================================================================== */

window.TASK_CENTER_CONFIG = {
  url:       "",                       // pl. "https://xxxx.supabase.co"
  anonKey:   "",                       // anon / publishable key (RLS mellett publikus lehet)
  boardKey:  "main_user_dashboard",    // task_center.boards.board_key
  realtime:  true
};

(function () {
  const cfg = window.TASK_CENTER_CONFIG;

  if (!cfg.url || !cfg.anonKey || typeof window.supabase === "undefined") {
    window.TaskCenterBackend = null;
    window.dispatchEvent(new CustomEvent("tc-backend-ready", { detail: { mode: "local" } }));
    return;
  }

  const sb = window.supabase.createClient(cfg.url, cfg.anonKey, {
    auth: { persistSession: true, autoRefreshToken: true },
    realtime: { params: { eventsPerSecond: 10 } }
  });

  const sc = () => sb.schema("task_center");

  // v_task_cards_frontend sor → frontend belső kártya
  function rowToCard(r) {
    return {
      id: r.task_id, boardKey: r.board_key, title: r.title, description: r.description,
      status: r.status_key === "approval_wait" ? "waiting" : r.status_key,
      priority: r.priority_key, module_key: r.module_key, module_label: r.module_label,
      source: { type: r.source_type, schema: r.source_schema, table: r.source_table, pk: r.source_pk, url: r.source_url, payload: r.source_payload },
      assignee: r.assignee_user_id, assigneeName: r.assignee_name, assigneeInitials: r.assignee_initials, assigneeColor: r.assignee_color,
      createdBy: r.created_by_user_id, due_at: r.due_at, progress: r.progress_percent || 0,
      tags: (r.tags || []).map(t => typeof t === "string" ? t : t.label || t.key),
      metadata: r.metadata || {}, ai_state: r.ai_state || "none", ai_summary: r.ai_summary, ai_suggestion: r.ai_suggestion || {},
      notification_state: r.notification_state || "none",
      checklist_total: r.checklist_total || 0, checklist_done: r.checklist_done || 0, comment_count: r.comment_count || 0,
      sort_order: r.sort_order, created_at: r.created_at, updated_at: r.updated_at,
      checklist: [], comments: [], activity: []
    };
  }
  const colKey = (s) => s === "waiting" ? "approval_wait" : s; // frontend → DB

  window.TaskCenterBackend = {
    mode: "supabase", client: sb, config: cfg,

    async currentUser() {
      const { data: { user } } = await sb.auth.getUser();
      return user ? user.id : null;
    },

    async listCards() {
      const { data, error } = await sc().from("v_task_cards_frontend").select("*")
        .eq("board_key", cfg.boardKey).order("sort_order", { ascending: true });
      if (error) throw error;
      return (data || []).map(rowToCard);
    },

    async listMembers() {
      const { data, error } = await sc().from("v_board_members").select("*")
        .eq("board_key", cfg.boardKey).order("sort_order", { ascending: true });
      if (error) throw error;
      return (data || []).map(m => ({
        id: m.user_id, name: m.name, initials: m.initials, color: m.color, avatar_url: m.avatar_url,
        role: m.role, online: false,
        can_view: m.can_view, can_create: m.can_create, can_edit_all: m.can_edit_all, can_manage_board: m.can_manage_board
      }));
    },

    async listChecklist(taskId) {
      const { data } = await sc().from("task_checklist_items").select("*").eq("task_id", taskId).order("sort_order");
      return (data || []).map(i => ({ id: i.checklist_item_id, text: i.item_text, done: i.is_done }));
    },
    async listComments(taskId) {
      const { data } = await sc().from("task_comments").select("*, author:author_user_id(display_name,initials,avatar_color)")
        .eq("task_id", taskId).eq("is_deleted", false).order("created_at");
      return (data || []).map(c => ({ author: c.author?.display_name || "—", initials: c.author?.initials || "–", color: c.author?.avatar_color || "#6d717a", text: c.body, at: c.created_at }));
    },

    /* ---- WRITE (RLS dönti el, jogosult-e) ---- */
    async createTask(p) {
      const { data, error } = await sc().from("task_cards").insert({
        board_id: p.board_id, title: p.title, description: p.description || null,
        status_key: colKey(p.status || "new"), priority_key: p.priority || "normal",
        module_key: p.module_key || "general", module_label: p.module_label || "Általános",
        assignee_user_id: p.assignee || null, due_at: p.due_at || null,
        tags: p.tags || [], source_type: "manual"
      }).select().single();
      if (error) throw error;
      return data.task_id;
    },
    async moveTask(taskId, status, sortOrder, actor) {
      const { error } = await sc().rpc("move_task_card", { p_task_id: taskId, p_status_key: colKey(status), p_sort_order: sortOrder ?? null, p_actor_user_id: actor || null });
      if (error) throw error;
    },
    async updateField(taskId, key, value) {
      const map = { status: "status_key", priority: "priority_key", assignee: "assignee_user_id", due_at: "due_at", progress: "progress_percent", title: "title", description: "description", tags: "tags" };
      const col = map[key] || key;
      const val = col === "status_key" ? colKey(value) : value;
      const { error } = await sc().from("task_cards").update({ [col]: val }).eq("task_id", taskId);
      if (error) throw error;
    },
    async deleteTask(taskId) {
      const { error } = await sc().from("task_cards").update({ is_deleted: true }).eq("task_id", taskId);
      if (error) throw error;
    },
    async addComment(taskId, body, authorId) {
      const { error } = await sc().from("task_comments").insert({ task_id: taskId, body, author_user_id: authorId || null });
      if (error) throw error;
    },
    async setChecklist(taskId, items) {
      await sc().from("task_checklist_items").delete().eq("task_id", taskId);
      if (items.length) await sc().from("task_checklist_items").insert(items.map((it, i) => ({ task_id: taskId, item_text: it.text, is_done: it.done, sort_order: (i + 1) * 100 })));
    },
    async notify(taskId, recipientId, title, body) {
      const { error } = await sc().from("task_notifications").insert({ task_id: taskId, recipient_user_id: recipientId || null, title, body });
      if (error) throw error;
    },
    async queueAgent(taskId, agentKey, jobType, payload, actor) {
      const { data, error } = await sc().rpc("queue_agent_job", { p_task_id: taskId, p_agent_key: agentKey || "task_assistant", p_job_type: jobType || "prepare_checklist", p_input_payload: payload || {}, p_requested_by_user_id: actor || null });
      if (error) throw error;
      return data;
    },
    async applyAgentResult(taskId, suggestion) {
      // AI eredmény jóváhagyás utáni alkalmazása (auditálható)
      const { error } = await sc().from("task_cards").update({ ai_state: "applied", ai_summary: suggestion.summary || null, ai_suggestion: suggestion }).eq("task_id", taskId);
      if (error) throw error;
    },

    /* ---- AI AGENTEK ---- */
    async listAgents() {
      const { data, error } = await sc().from("ai_agents")
        .select("agent_key,display_name,agent_type,description,icon,status,can_write,model,run_count,last_run_label,write_scopes")
        .eq("board_key", cfg.boardKey).order("sort_order", { ascending: true });
      if (error) throw error;
      return (data || []).map(a => ({
        id: a.agent_key, name: a.display_name, type: a.agent_type, desc: a.description, icon: a.icon || "✦",
        status: a.status, canWrite: a.can_write, model: a.model, runs: a.run_count || 0,
        lastRun: a.last_run_label || "–", scopes: a.write_scopes || []
      }));
    },
    async setAgentStatus(agentKey, status) {
      // RLS: csak manage_board jogú user módosíthat
      const { error } = await sc().from("ai_agents").update({ status }).eq("agent_key", agentKey).eq("board_key", cfg.boardKey);
      if (error) throw error;
    },
    async setAgentWrite(agentKey, canWrite) {
      const { error } = await sc().from("ai_agents").update({ can_write: canWrite }).eq("agent_key", agentKey).eq("board_key", cfg.boardKey);
      if (error) throw error;
    },

    /* ---- AUTOMATIZMUSOK ---- */
    async listAutomations() {
      const { data, error } = await sc().from("automation_rules")
        .select("rule_key,name,is_enabled,trigger_type,action_type,agent_key,run_count,last_run_label")
        .eq("board_key", cfg.boardKey).order("created_at", { ascending: true });
      if (error) throw error;
      return (data || []).map(r => ({
        id: r.rule_key, name: r.name, enabled: r.is_enabled, trigger: r.trigger_type,
        action: r.action_type, agentId: r.agent_key || "", runs: r.run_count || 0, lastRun: r.last_run_label || "–"
      }));
    },
    async upsertAutomation(rule) {
      const { error } = await sc().from("automation_rules").upsert({
        rule_key: rule.id, board_key: cfg.boardKey, name: rule.name, is_enabled: rule.enabled,
        trigger_type: rule.trigger, action_type: rule.action, agent_key: rule.agentId || null
      }, { onConflict: "rule_key" });
      if (error) throw error;
    },
    async deleteAutomation(ruleKey) {
      const { error } = await sc().from("automation_rules").delete().eq("rule_key", ruleKey).eq("board_key", cfg.boardKey);
      if (error) throw error;
    },
    async runAutomation(ruleKey, actor) {
      const { data, error } = await sc().rpc("run_automation_rule", { p_rule_key: ruleKey, p_actor_user_id: actor || null });
      if (error) throw error;
      return data;
    },

    subscribe(onChange) {
      if (!cfg.realtime) return () => {};
      const ch = sb.channel("task_center_rt")
        .on("postgres_changes", { event: "*", schema: "task_center", table: "task_cards" }, p => onChange && onChange(p))
        .on("postgres_changes", { event: "INSERT", schema: "task_center", table: "task_notifications" }, p => onChange && onChange({ ...p, _notification: true }))
        .on("postgres_changes", { event: "*", schema: "task_center", table: "agent_jobs" }, p => onChange && onChange({ ...p, _agent: true }))
        .on("postgres_changes", { event: "*", schema: "task_center", table: "automation_rules" }, p => onChange && onChange({ ...p, _automation: true }))
        .subscribe();
      return () => sb.removeChannel(ch);
    }
  };

  window.dispatchEvent(new CustomEvent("tc-backend-ready", { detail: { mode: "supabase" } }));
})();
