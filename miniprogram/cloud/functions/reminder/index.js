"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// cloud/functions/reminder/index.ts
var index_exports = {};
__export(index_exports, {
  main: () => main
});
module.exports = __toCommonJS(index_exports);
var import_wx_server_sdk = __toESM(require("wx-server-sdk"));
import_wx_server_sdk.default.init({ env: import_wx_server_sdk.default.DYNAMIC_CURRENT_ENV });
var db = import_wx_server_sdk.default.database();
var _ = db.command;
var JOB_LIMIT = 100;
async function mark(jobId, status, extra = {}) {
  await db.collection("dp_jobs").doc(jobId).update({
    data: { status, updatedAt: db.serverDate(), ...extra }
  });
}
async function main() {
  const now = /* @__PURE__ */ new Date();
  const due = await db.collection("dp_jobs").where({ status: "pending", sendAt: _.lte(now) }).limit(JOB_LIMIT).get();
  let sent = 0;
  let invalid = 0;
  let failed = 0;
  for (const job of due.data) {
    if (!job.templateId || !job._openid) {
      await mark(job.id, "invalid", { failure: "missing_template_or_openid" });
      invalid += 1;
      continue;
    }
    const data = job.payload && typeof job.payload === "object" ? job.payload : {};
    try {
      await import_wx_server_sdk.default.openapi.subscribeMessage.send({
        touser: job._openid,
        templateId: job.templateId,
        page: job.page || void 0,
        data,
        miniprogramState: "formal",
        lang: "zh_CN"
      });
      await mark(job.id, "sent", { sentAt: db.serverDate() });
      sent += 1;
    } catch (error) {
      const code = error?.errCode ?? error?.errcode ?? null;
      if (code === 43101 || code === 47003) {
        await mark(job.id, "invalid", {
          failure: String(code)
        });
        invalid += 1;
      } else {
        await mark(job.id, "failed", {
          failure: String(code ?? error?.errMsg ?? "send_failed")
        });
        failed += 1;
      }
    }
  }
  return { ok: true, checked: due.data.length, sent, invalid, failed };
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  main
});
