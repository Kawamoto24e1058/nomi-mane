<script lang="ts">
  // @ts-nocheck
  import { db } from "$lib/firebase";
  import { collection, addDoc, serverTimestamp } from "firebase/firestore";
  import { goto } from "$app/navigation";
  import { onMount } from "svelte";
  import { browser } from "$app/environment";

  let hostName = "";
  let baseFee = 1000;
  let paypayUrl = "";
  let bankInfo = "";
  let isLoading = false;
  let isMounted = false;

  let showScanner = false;
  let html5QrCode: any = null;
  let scannerError = "";

  onMount(() => {
    isMounted = true;
    return () => {
      if (html5QrCode) {
        html5QrCode.stop().catch(console.error);
      }
    };
  });

  async function startScanner() {
    if (!browser) return;
    showScanner = true;
    scannerError = "";

    // 短いラグを入れてDOMのレンダリングを待つ
    setTimeout(async () => {
      try {
        // 動的インポート
        const { Html5Qrcode } = await import("html5-qrcode");

        html5QrCode = new Html5Qrcode("reader");
        const config = { fps: 10, qrbox: { width: 250, height: 250 } };

        await html5QrCode.start(
          { facingMode: "environment" },
          config,
          (decodedText) => {
            // スキャン成功
            handleScanResult(decodedText);
          },
          (errorMessage) => {
            // スキャン中（エラーではない）
          },
        );
      } catch (err) {
        console.error("Scanner Error:", err);
        scannerError = "カメラの起動に失敗しました。";
      }
    }, 300);
  }

  async function stopScanner() {
    if (html5QrCode) {
      await html5QrCode.stop();
      html5QrCode = null;
    }
    showScanner = false;
  }

  function handleScanResult(result: string) {
    // URLパース
    try {
      const url = new URL(result);
      // このアプリのドメインか、相対パスかチェック
      if (url.pathname.startsWith("/join/")) {
        stopScanner();
        goto(url.pathname);
      } else {
        // 全く違うURLの場合
        alert("有効な飲みマネの招待コードではありません。");
      }
    } catch (e) {
      // URLではない文字列の場合も同様
      if (result.startsWith("/join/")) {
        stopScanner();
        goto(result);
      } else {
        alert("有効なコードではありません。");
      }
    }
  }

  async function createRoom(event?: Event) {
    if (!hostName) {
      if (browser) {
        alert("エラー：幹事の名前が入力されていません");
      }
      return;
    }

    isLoading = true;
    try {
      const docRef = await addDoc(collection(db, "rooms"), {
        hostName,
        baseFee: Number(baseFee),
        paypayUrl,
        bankInfo,
        createdAt: serverTimestamp(),
      });
      goto(`/host/${docRef.id}`);
    } catch (e: any) {
      console.error("Firestore Error:", e);
      if (browser) {
        alert("ルームの作成に失敗しました。理由: " + e.message);
      }
    } finally {
      isLoading = false;
    }
  }

  function useTemplateA() {
    bankInfo = "銀行名：\n支店名：\n種別：普通\n口座番号：\n名義（カナ）：";
  }

  function useTemplateB() {
    bankInfo = "ことら送金（電話番号等）：\n名義（カナ）：";
  }
</script>

<svelte:head>
  <title>飲みマネ - 飲み会ルーム作成</title>
</svelte:head>

<main class="max-w-md mx-auto px-6 py-12">
  <div class="text-center mb-10">
    <h1 class="text-3xl font-black text-paypay-red italic mb-2">飲みマネ</h1>
    <p class="text-gray-500 font-medium text-sm">
      飲み会の集計を、もっとスマートに。
    </p>
  </div>

  <form on:submit|preventDefault={createRoom} class="space-y-8">
    <div class="space-y-4">
      <label class="block">
        <span class="text-sm font-bold text-gray-700 ml-1">幹事のお名前</span>
        <input
          required
          type="text"
          bind:value={hostName}
          placeholder="例: たろう"
          class="mt-1 block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white transition-all outline-none"
        />
      </label>

      <label class="block">
        <span class="text-sm font-bold text-gray-700 ml-1">基本会費 (円)</span>
        <input
          required
          type="number"
          bind:value={baseFee}
          class="mt-1 block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white transition-all outline-none"
        />
      </label>

      <div class="space-y-2">
        <div class="flex items-center justify-between ml-1">
          <span class="text-sm font-bold text-gray-700"
            >PayPay マイコードURL</span
          >
          <a
            href="paypay://"
            class="text-[10px] font-bold bg-paypay-red text-white px-3 py-1 rounded-full shadow-sm active:scale-95 transition-all flex items-center gap-1"
          >
            📱 PayPayを開く
          </a>
        </div>
        <input
          type="url"
          bind:value={paypayUrl}
          placeholder="https://paypay.ne.jp/..."
          class="block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white transition-all outline-none"
        />
        <p class="text-[10px] text-gray-400 font-medium leading-relaxed px-1">
          ※PayPayアプリの右下にある『アカウント』＞『マイコード』からリンクを作成してコピーしてください
        </p>
      </div>

      <div class="space-y-2">
        <span class="text-sm font-bold text-gray-700 ml-1"
          >銀行口座 / ことら送金</span
        >
        <div class="flex gap-2">
          <button
            type="button"
            on:click={useTemplateA}
            class="text-[10px] bg-white border border-gray-200 text-paypay-red px-2 py-1 rounded-md shadow-sm"
            >🏦 口座雛形</button
          >
          <button
            type="button"
            on:click={useTemplateB}
            class="text-[10px] bg-white border border-gray-200 text-paypay-red px-2 py-1 rounded-md shadow-sm"
            >📱 ことら雛形</button
          >
        </div>
        <textarea
          bind:value={bankInfo}
          rows="4"
          placeholder="振込先情報を入力"
          class="mt-1 block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white transition-all outline-none text-sm"
        ></textarea>
      </div>
    </div>

    <!-- type="submit" にすることで、Form全体のバリデーションやEnterキー送信も有効になります -->
    <button
      type="submit"
      class="btn-primary w-full flex items-center justify-center gap-2"
    >
      {#if isLoading}
        <span class="animate-spin text-xl">🌀</span>
      {:else}
        飲み会ルームを作成
      {/if}
    </button>

    <div class="relative py-4">
      <div class="absolute inset-0 flex items-center" aria-hidden="true">
        <div class="w-full border-t border-gray-100"></div>
      </div>
      <div class="relative flex justify-center text-xs uppercase">
        <span class="bg-white px-4 text-gray-300 font-bold">OR</span>
      </div>
    </div>

    <button
      type="button"
      on:click={startScanner}
      class="w-full bg-gray-50 text-gray-700 font-black py-4 rounded-2xl border-2 border-transparent hover:border-paypay-red hover:bg-red-50 transition-all flex items-center justify-center gap-2"
    >
      📷 QRコードをスキャンして参加
    </button>
  </form>

  {#if showScanner}
    <div
      class="fixed inset-0 z-50 bg-black flex flex-col items-center justify-center p-6"
    >
      <div
        class="w-full max-w-sm aspect-square bg-gray-900 rounded-3xl overflow-hidden relative shadow-2xl border-4 border-paypay-red"
        id="reader"
      >
        {#if scannerError}
          <div
            class="absolute inset-0 flex items-center justify-center text-white text-center p-4"
          >
            <p class="font-bold">{scannerError}</p>
          </div>
        {/if}
      </div>

      <p class="text-white mt-8 font-bold text-center">
        招待QRコードを枠内に収めてください
      </p>

      <button
        on:click={stopScanner}
        class="mt-12 bg-white/10 text-white border border-white/20 px-8 py-3 rounded-full font-bold hover:bg-white/20 transition-all"
      >
        キャンセル
      </button>
    </div>
  {/if}
</main>
