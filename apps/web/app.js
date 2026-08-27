const input = document.querySelector('#event');
const button = document.querySelector('#send');
const status = document.querySelector('#status');
const result = document.querySelector('#result');

button.addEventListener('click', async () => {
  status.textContent = '正在请求后端…';
  result.hidden = true;
  try {
    const response = await fetch('/api/comfort', {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ event: input.value })
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.message);
    document.querySelector('#reply').textContent = data.reply;
    document.querySelector('#actions').innerHTML = data.actions.map((item, index) => `<p><b>0${index + 1}</b>${item}</p>`).join('');
    document.querySelector('#version').textContent = `共同契约版本 ${data.contractVersion}`;
    status.textContent = '前后端通信成功'; result.hidden = false;
  } catch (error) { status.textContent = error.message || '请求失败'; }
});
