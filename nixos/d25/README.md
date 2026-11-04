# d25

## UPS

At 50% UPS charge, UPower powers the host off, or puts it into hybrid sleep
once hibernation works. Where losing work matters, keep autosave intervals
under 25 min.

## Monitor brightness control slider

The GNOME brightness slider controls external monitors over DDC/CI. The boot
waits for monitors listed in `hardware.ddcciBacklight.monitors` in
[configuration.nix](configuration.nix). Other monitors have no slider unless
they answer at once. Add a new monitor to the list so the boot waits for it
too, the option description in
[modules/ddcci-backlight](modules/ddcci-backlight/default.nix) shows how to
print its name.

## vLLM

[vllm.nix](vllm.nix) runs vLLM in Docker as the system service.

### Usage

```sh
systemctl status docker-vllm.service
journalctl -u docker-vllm.service -f
curl --fail http://127.0.0.1:8000/health
curl --fail http://127.0.0.1:8000/v1/models
curl --fail http://127.0.0.1:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"google/gemma-4-E4B-it","messages":[{"role":"user","content":"Reply with OK."}],"max_tokens":32,"chat_template_kwargs":{"enable_thinking":false}}'
```

### References

- [vLLM CPU installation](https://docs.vllm.ai/en/stable/getting_started/installation/cpu/)
- [Gemma 4 recipe](https://github.com/vllm-project/recipes/blob/main/Google/Gemma4.md)
- [vLLM server configuration](https://docs.vllm.ai/en/stable/configuration/serve_args/)
- [Hugging Face cache](https://huggingface.co/docs/huggingface_hub/guides/manage-cache)
