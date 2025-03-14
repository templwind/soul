<script lang="ts">
	type MessageType = 'error' | 'success' | 'info';
	type MessageKey = 'expired' | 'invalid' | 'not-found' | 'verified' | 'failed' | 'success';

	interface Message {
		title: string;
		message: string;
		type: MessageType;
	}

	const messages: Record<MessageKey, Message> = {
		expired: {
			title: 'Verification Link Expired',
			message: 'Your verification link has expired. Please request a new verification email.',
			type: 'error'
		},
		invalid: {
			title: 'Invalid Verification Link',
			message:
				'The verification link you clicked is invalid. Please check your email for the correct link.',
			type: 'error'
		},
		'not-found': {
			title: 'User Not Found',
			message: 'We could not find a user associated with this verification link.',
			type: 'error'
		},
		verified: {
			title: 'Already Verified',
			message: 'Your email has already been verified. You can proceed to login.',
			type: 'info'
		},
		failed: {
			title: 'Verification Failed',
			message: 'There was an error verifying your email. Please try again later.',
			type: 'error'
		},
		success: {
			title: 'Email Verified',
			message: 'Your email has been successfully verified. You can now login to your account.',
			type: 'success'
		}
	};

	const props: {
		data: {
			kind: MessageKey;
		};
	} = $props();

	let currentMessage = $state(messages[props.data.kind]);

	$effect(() => {
		currentMessage = messages[props.data.kind as MessageKey];
	});
</script>

<div class="min-h-[50vh] flex items-center justify-center">
	<div class="w-full max-w-md px-4">
		{#if currentMessage}
			<div
				class="alert {currentMessage.type === 'success'
					? 'alert-success'
					: currentMessage.type === 'error'
						? 'alert-error'
						: 'alert-info'} mb-6"
			>
				<div class="flex flex-col items-center gap-2">
					<!-- Alert Icon -->
					{#if currentMessage.type === 'success'}
						<svg
							xmlns="http://www.w3.org/2000/svg"
							class="w-6 h-6"
							fill="none"
							viewBox="0 0 24 24"
							stroke="currentColor"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
							></path>
						</svg>
					{:else if currentMessage.type === 'error'}
						<svg
							xmlns="http://www.w3.org/2000/svg"
							class="w-6 h-6"
							fill="none"
							viewBox="0 0 24 24"
							stroke="currentColor"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
							></path>
						</svg>
					{:else}
						<svg
							xmlns="http://www.w3.org/2000/svg"
							class="w-6 h-6"
							fill="none"
							viewBox="0 0 24 24"
							stroke="currentColor"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
							></path>
						</svg>
					{/if}

					<h3 class="text-lg font-bold">
						{currentMessage.title}
					</h3>
					<div class="text-sm">
						{currentMessage.message}
					</div>
				</div>
			</div>

			<div class="text-center">
				<a href="/auth/login" class="btn btn-primary"> Go to Login </a>
			</div>
		{:else}
			<div class="alert alert-error">
				<div class="flex flex-col items-center gap-2">
					<svg
						xmlns="http://www.w3.org/2000/svg"
						class="w-6 h-6"
						fill="none"
						viewBox="0 0 24 24"
						stroke="currentColor"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
						></path>
					</svg>
					<h3 class="text-lg font-bold">Invalid Status</h3>
					<div class="text-sm">An invalid verification status was provided.</div>
				</div>
			</div>
		{/if}
	</div>
</div>
