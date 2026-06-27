// Retool iframe bridge snippets
// Assumption: iframe component is named iFrameUserDashboard.
// Keep this dashboard standalone; only use bridge if opened from Retool.

// 1) Send tasks to dashboard
function sendTasksToDashboard() {
  const iframe = iFrameUserDashboard?.iframe?.contentWindow || document.querySelector('iframe')?.contentWindow;
  if (!iframe) return;

  iframe.postMessage({
    type: 'task_center_set_tasks',
    payload: {
      tasks: qTaskCenterCards.data
    }
  }, '*');
}

// 2) Send users to dashboard
function sendUsersToDashboard() {
  const iframe = iFrameUserDashboard?.iframe?.contentWindow || document.querySelector('iframe')?.contentWindow;
  if (!iframe) return;

  iframe.postMessage({
    type: 'task_center_set_users',
    payload: {
      users: qTaskCenterUsers.data
    }
  }, '*');
}

// 3) Listen for dashboard actions
window.addEventListener('message', async (event) => {
  const msg = event.data || {};
  if (msg.source !== 'feladatkozpont') return;

  switch (msg.type) {
    case 'task_center_status_change':
      await qMoveTaskCard.trigger({ additionalScope: msg.payload });
      break;
    case 'task_center_create_task':
      await qCreateTaskCard.trigger({ additionalScope: msg.payload });
      break;
    case 'task_center_update_field':
      await qUpdateTaskField.trigger({ additionalScope: msg.payload });
      break;
    case 'task_center_queue_agent':
      await qQueueAgentJob.trigger({ additionalScope: msg.payload });
      break;
    case 'task_center_open_source':
      // Implement route based on source_url/source_pk/source_table.
      utils.showNotification({ title: 'Forrás megnyitás', description: JSON.stringify(msg.payload), notificationType: 'info' });
      break;
  }
});
