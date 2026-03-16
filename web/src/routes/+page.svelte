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

  onMount(() => {
    isMounted = true;
  });

  async function createRoom(event?: Event) {
    if (!hostName) {
      if (browser) {
        alert('エラー：幹事の名前が入力されていません');
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
        createdAt: serverTimestamp()
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
    <p class="text-gray-500 font-medium text-sm">飲み会の集計を、もっとスマートに。</p>
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

      <label class="block">
        <span class="text-sm font-bold text-gray-700 ml-1">PayPay マイコードURL</span>
        <input
          type="url"
          bind:value={paypayUrl}
          placeholder="https://paypay.ne.jp/..."
          class="mt-1 block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white transition-all outline-none"
        />
      </label>

      <div class="space-y-2">
        <span class="text-sm font-bold text-gray-700 ml-1">銀行口座 / ことら送金</span>
        <div class="flex gap-2">
          <button type="button" on:click={useTemplateA} class="text-[10px] bg-white border border-gray-200 text-paypay-red px-2 py-1 rounded-md shadow-sm">🏦 口座雛形</button>
          <button type="button" on:click={useTemplateB} class="text-[10px] bg-white border border-gray-200 text-paypay-red px-2 py-1 rounded-md shadow-sm">📱 ことら雛形</button>
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
  </form>
</main>
